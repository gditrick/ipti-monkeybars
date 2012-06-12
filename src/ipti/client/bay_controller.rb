require 'app/d4_module/d4_module_model'
require 'app/oc_module/oc_module_model'

module IPTI
  module Client
    class BayController < IPTI::Controller
      attr_accessor :d4_modules, :lp_modules, :oc_modules

      message_type :heartbeat,           :code => "01"
      message_type :verify_turn_all_on,  :code => "02",
                                         :response_handler => :verify_turn_on
      message_type :verify_turn_all_off, :code => "03",
                                         :response_handler => :verify_turn_off
      message_type :turn_one_on,         :code => "04"
      message_type :turn_one_off,        :code => "05"
      message_type :turn_all_on,         :code => "06"
      message_type :turn_all_off,        :code => "07"
      message_type :cancel_order,        :code => "14",
                                         :response_handler => :cancel_order,
                                         :formatter        => :format_cancel_order
      message_type :oc_display,          :code => "27",
                                         :response_handler => :oc_display_text,
                                         :formatter        => :format_oc_display_text
      message_type :get_valid_oc,        :code => "30",
                                         :response_handler => :get_oc_modules,
                                         :formatter        => :format_oc_modules
      message_type :d4_display,          :code => "33",
                                         :response_handler => :d4_display_order,
                                         :formatter        => :format_d4_display_order,
                                         :ack_handler      => :ack_d4_display_order
      message_type :set_num_of_devices,  :code => "81",
                                         :response_handler => :get_modules,
                                         :formatter => :format_modules
      message_type :reset,               :code => "99",
                                         :response_handler => :reset

      def initialize(address, connection)
        super(address, connection)
        @seq = 0
        @d4_modules, @d4_list, @d4_starting_addr = {}, [], "00"
        @lp_modules, @lp_list, @lp_starting_addr = {}, [], "00"
        @oc_modules, @oc_list, @oc_starting_addr = {}, [], "00"
        @bay_model = self.connection.app.light_bar.bays.select{|a| a.address == address }.first
        unless  @bay_model.nil?
          @main_oc = @bay_model.main_oc
          @bay_model.devices.each do |device|
             case device
               when D4ModuleModel then
                 @d4_list << device
                 @d4_modules[device.address] = device
               when OcModuleModel then
                 @oc_list << device
                 @oc_modules[device.address] = device
             end
          end
        end
        @d4_starting_addr = @d4_list.map(&:address).min unless @d4_list.empty?
        @lp_starting_addr = @lp_list.map(&:address).min unless @lp_list.empty?
        @oc_starting_addr = @oc_list.map(&:address).min unless @oc_list.empty?

        BayController.instances[IPTI::Controller.key(address, connection)] = self
      end

      def connect_comm
        @in_queue        = EventMachine::Queue.new
        @out_queue       = EventMachine::Queue.new
        @in_queue_mutex  = Mutex.new
        @out_queue_mutex = Mutex.new
        @bay_bus         = CommunicationBus.new
        @bus_timer       = EM::PeriodicTimer.new(0.01) { process_comm_bus }
        @d4_list.each{|a| a.bus = @bay_bus }
        @oc_list.each{|a| a.bus = @bay_bus }
        @lp_list.each{|a| a.bus = @bay_bus }
      end

      def process_comm_bus
        bus_msg = @bay_bus.pop_bus_msg
        unless bus_msg.nil?
          m_type = self.message_types[bus_msg.code]
          unless m_type.nil?
            message = IPTI::PickMaxMessage.new(self, m_type, @seq)
            message.fields = bus_msg.fields
            message.sequence = @seq
            message.response_required=true
            @connection.push_out_msg(message)
          else
            raise "Message Request #{bus_msg.code} not implemented"
          end
        end
      end

      def bump_seq
        @seq = @seq + 1 >= 100 ?  0 : @seq + 1
      end

      def reset(message)
        msg = IPTI::PickMaxMessage.new(self, self.message_types[:reset], @seq, message.bytes)
        msg.sequence = message.sequence
        if msg.format == message.bytes
          @seq = 99
        end
        msg = IPTI::PickMaxMessage.new(self, self.message_types[:reset], @seq, message.bytes)
        msg.sequence = @seq
        msg.response_required = true
        msg
      end

      def get_oc_modules(message)
        oc_msg = IPTI::PickMaxMessage.new(self, self.message_types[:get_valid_oc])
        oc_msg.fields[:main_oc_present] = (not @main_oc.nil?)
        oc_msg.fields[:oc_addresses]    = @oc_list.map(&:address)
        oc_msg.fields[:ack]             = true
        oc_msg.sequence = message.sequence
        oc_msg
      end

      def format_oc_modules(args={})
        return "'" if args.empty?
        msg = format_true_false(args[:main_oc_present])
        args[:oc_addresses].inject(msg) {|m,o| m += o }
      end

      def get_modules(message)
        modules_msg = IPTI::PickMaxMessage.new(self, self.message_types[:set_num_of_devices])
        modules_msg.fields[:number_of_d4]     = @d4_list.size
        modules_msg.fields[:number_of_lp]     = @lp_list.size
        modules_msg.fields[:starting_d4_addr] = @d4_starting_addr
        modules_msg.fields[:starting_lp_addr] = @lp_starting_addr
        modules_msg.fields[:ack]             = true
        modules_msg.sequence = message.sequence
        modules_msg
      end

      def format_modules(args={})
        return "'" if args.empty?
        '%-2.2d%-2.2d%s%s' % [args[:number_of_d4],
                              args[:number_of_lp],
                              args[:starting_d4_addr],
                              args[:starting_lp_addr]
        ]
      end

      def d4_display_order(message)
        d4_msg = IPTI::PickMaxMessage.new(self, self.message_types[:d4_display])
        if message.bytes.size > 11
          d4_addr = message.bytes.slice(7,2)
          d4_module = @d4_modules[d4_addr]
          d4_msg.fields[:d4_address] = d4_addr
          if d4_module.nil?
            d4_msg.fields[:success] = false
          else
            d4_module.push_msg(message)
            d4_msg.fields[:success] = true
          end
          d4_msg.fields[:ack] = true
          d4_msg.sequence = message.sequence
        end
        d4_msg
      end

      def format_d4_display_order(args={})
        return "'" if args.empty?
        if args.has_key?(:success) and args.has_key?(:ack)
          "%s%s" % [args[:d4_address], format_true_false(args[:success])]
        elsif args.has_key?(:quantity) and args.has_key?(:led_states)
          "%s%4.4d%s%X" % [args[:d4_address],
                           args[:quantity],
                           args[:infrared],
                           args[:led_states]]
        else
          "%s" % [args[:d4_address]]
        end
      end

      def ack_d4_display_order(message)
        d4_msg = IPTI::PickMaxMessage.new(self, self.message_types[:d4_display], message.sequence, message.bytes)
        d4_addr = d4_msg.bytes.slice(7,2)
        d4_msg.fields[:d4_address] = d4_addr
        d4_msg.fields[:ack] = true
        d4_msg.format
      end

      def oc_display_text(message)
        oc_msg = IPTI::PickMaxMessage.new(self, self.message_types[:oc_display])
        if message.bytes.size > 10
          oc_addr = message.bytes.slice(7,2)
          oc_module = @oc_modules[oc_addr]
          if oc_module.nil?
            oc_msg.fields[:success] = false
          else
            oc_msg.fields[:success] = true
            oc_module.push_msg(message)
          end
          oc_msg.fields[:ack] = true
          oc_msg.sequence = message.sequence
        end
        oc_msg
      end

      def format_oc_display_text(args={})
        return "'" if args.empty?
        if args.has_key?(:success)
          args[:success] ? "" : "ER"
        else
          "%s%X" % [args[:button_pressed],
                    args[:oc_address]]
        end
      end

      def cancel_order(message)
        cancel_msg = IPTI::PickMaxMessage.new(self, self.message_types[:cancel_order])
        cancel_types = message.bytes.slice(7,2)
        oc_modules_to_cancel = []
        d4_modules_to_cancel = []
        lp_modules_to_cancel = []
        field_hash = {}
        field_hash.merge!({:success => true })
        case cancel_types
          when "00" then
            field_hash.merge!({:cancel_type => '00'})
            field_hash.merge!({:success => true })
            oc_modules_to_cancel = self.oc_modules
            d4_modules_to_cancel = self.d4_modules
            lp_modules_to_cancel = self.lp_modules
          when "OC" then
            field_hash.merge!({:cancel_type => 'OC'})
            oc_addresses = message.bytes.slice(9..-3)
            addresses = []
            while (oc_addr = oc_addresses.slice!(0,2)) != ""
              addresses << oc_addr
              oc_module_to_cancel = self.oc_modules[oc_addr]
              if oc_module_to_cancel.nil?
                field_hash.merge!({:success => false})
              else
                oc_modules_to_cancel << oc_module_to_cancel
              end
            end
            field_hash.merge!({:addresses => addresses})
          else
            device_addresses = message.bytes.slice(7..-3)
            addresses = []
            while (addr = device_addresses.slice!(0,2)) != ""
              addresses << addr
              d4_module_to_cancel = self.d4_modules[addr]
              d4_modules_to_cancel << d4_module_to_cancel unless d4_module_to_cancel.nil?
              lp_module_to_cancel = self.lp_modules[addr]
              lp_modules_to_cancel << lp_module_to_cancel unless lp_module_to_cancel.nil?
            end
            field_hash.merge!({:addresses => addresses})
        end
        oc_modules_to_cancel.each{ |a| a.push_msg(message) }
        d4_modules_to_cancel.each{ |a| a.push_msg(message) }
        lp_modules_to_cancel.each{ |a| a.push_msg(message) }
        field_hash.merge!({:ack => true})
        cancel_msg.fields = field_hash
        cancel_msg.sequence = message.sequence
        cancel_msg
      end

      def format_cancel_order(args={})
        return "'" if args.empty?
        msg = ""
        msg += args[:cancel_type] unless args[:cancel_type].nil?
        args[:addresses].each { |addr| msg += addr} unless args[:addresses].nil?
        msg
      end
    end
  end
end

