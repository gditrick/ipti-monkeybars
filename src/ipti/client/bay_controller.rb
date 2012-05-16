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
        @in_timer        = EM::PeriodicTimer.new(0.01) { process_in_queue }
        @out_timer       = EM::PeriodicTimer.new(0.01) { process_out_queue }
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
            self.bump_seq
            @connection.push_out_msg({:data => '', :controller => self, :type => m_type, :fields => bus_msg.fields})
          else
            raise "Message Request #{bus_msg.code} not implemented"
          end
        end
      end

      def seq
        ("%2.2d" % @seq).slice(-2,2) + ":"
      end

      def bump_seq
        @seq = @seq >= 100 ?  0 : @seq + 1
      end

      def reset(msg_hash)
        msg = msg_hash[:msg]
        reset_msg =  self.message_types[:reset].message(self)
        reset_msg += IPTI::PickMaxProtocol.check_sum(reset_msg)
        if msg == reset_msg
          @seq = 0
        end
        self.wait_for_ack
        msg
      end

      def get_oc_modules(msg_hash)
        msg_hash.merge!({:fields => {:main_oc_present => (not @main_oc.nil?),
                                     :oc_addresses    => @oc_list.map(&:address)
                                    }
        })
        self.ack
      end

      def format_oc_modules(args=nil)
        return "'" if args.nil? or args.empty?
        msg = format_true_false(args[0][:main_oc_present])
        args[0][:oc_addresses].inject(msg) {|m,o| m += o }
      end

      def get_modules(msg_hash)
        msg_hash.merge!({:fields => {:number_of_d4     => @d4_list.size,
                                     :number_of_lp     => @lp_list.size,
                                     :starting_d4_addr => @d4_starting_addr,
                                     :starting_lp_addr => @lp_starting_addr
                                    }
        })
        self.ack
      end

      def format_modules(args=nil)
        return "'" if args.nil? or args.empty?
        '%-2.2d%-2.2d%s%s' % [args[0][:number_of_d4],
                              args[0][:number_of_lp],
                              args[0][:starting_d4_addr],
                              args[0][:starting_lp_addr]
        ]

      end

      def d4_display_order(msg_hash)
        unless self.idle?
          msg =  msg_hash[:msg]
          d4_addr = msg.slice(7,2)
          d4_module = @d4_modules[d4_addr]
          if d4_module.nil?
            msg_hash.merge!({:fields => {:d4_address => d4_addr,
                                         :success    => false }
                            })
          else
            msg_hash.merge!({:fields => {:d4_address => d4_module.address,
                                         :success    => true }
            })
            d4_module.push_msg(msg_hash)
          end
          self.ack
        end
      end

      def format_d4_display_order(args=nil)
pp "Format d4 display"
pp args
pp self.state_name
        return "'" if args.nil? or args.empty?

        case self.state_name
          when :idle then
            "%s%4.4d%s%X" % [args[0][:d4_address],
                             args[0][:quantity],
                             args[0][:infrared],
                             args[0][:led_states]]
          when :waiting_for_ack then
            "%s" % [args[0][:d4_address]]
          else
            "%s%s" % [args[0][:d4_address], format_true_false(args[0][:success])]
        end
      end

      def ack_d4_display_order(msg_hash)
        msg = msg_hash[:msg]
        d4_addr = msg.slice(7,2)
        msg_hash.merge!({:fields => {:d4_address => d4_addr }})
        format_d4_display_order(*(msg_hash[:fields]))
      end

      def oc_display_text(msg_hash)
        unless self.idle?
          msg =  msg_hash[:msg]
          oc_addr = msg.slice(7,2)
          oc_module = @oc_modules[oc_addr]
          if oc_module.nil?
            msg_hash.merge!({:fields => {:success    => false }})
          else
            msg_hash.merge!({:fields => {:success    => true }})
            oc_module.push_msg(msg_hash)
          end
          self.ack
        end
      end

      def format_oc_display_text(args=nil)
        return "'" if args.nil? or args.empty?
        if self.idle?
          "%s%X" % [args[0][:button_pressed],
                    args[0][:oc_address]]
        else
          if args[0][:success]
            ""
          else
            "ER"
          end
        end
      end

      def cancel_order(msg_hash)
        msg =  msg_hash[:msg]
        cancel_types = msg.slice(7,2)
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
            oc_addresses = msg.slice(9..-3)
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
            device_addresses = msg.slice(7..-3)
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
        msg_hash.merge!({:fields => field_hash})
        oc_modules_to_cancel.each{ |a| a.push_msg(msg_hash) }
        d4_modules_to_cancel.each{ |a| a.push_msg(msg_hash) }
        lp_modules_to_cancel.each{ |a| a.push_msg(msg_hash) }
        self.ack
      end

      def format_cancel_order(args=nil)
        return "'" if args.nil? or args.empty?
        msg = ""
        msg += args[0][:cancel_type] unless args[0][:cancel_type].nil?
        args[0][:addresses].each { |addr| msg += addr} unless args[0][:addresses].nil?
        msg
      end

    end
  end
end

