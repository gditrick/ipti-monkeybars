require 'app/d4_module/d4_module_model'
require 'app/oc_module/oc_module_model'

module IPTI
  module Client
    class BayController < IPTI::Controller
      attr_accessor :d4_modules, :lp_modules, :oc_modules

      message_type :heartbeat,           :code => "01"
      message_type :verify_turn_all_on,  :code => "02", :response_handler => :verify_turn_on
      message_type :verify_turn_all_off, :code => "03", :response_handler => :verify_turn_off
      message_type :turn_one_on,         :code => "04"
      message_type :turn_one_off,        :code => "05"
      message_type :turn_all_on,         :code => "06"
      message_type :turn_all_off,        :code => "07"
      message_type :get_valid_oc,        :code => "30", :response_handler => :get_oc_modules, :formatter => :format_oc_modules
      message_type :set_num_of_devices,  :code => "81", :response_handler => :get_modules,    :formatter => :format_modules
      message_type :reset,               :code => "99", :response_handler => :reset

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
        @in_queue   = EventMachine::Queue.new
        @out_queue  = EventMachine::Queue.new
        @in_queue_mutex  = Mutex.new
        @out_queue_mutex = Mutex.new
        @in_timer        = EM::PeriodicTimer.new(0.01) { process_in_queue }
        @out_timer       = EM::PeriodicTimer.new(0.01) { process_out_queue }
        #@number_of_bays  = @connection.app.light_bar.bays.size
        #@starting_bay_number = @connection.app.light_bar.bays[0].address
        #(0...@number_of_bays).each do |i|
        #  bay_controller = IPTI::Client::BayController.new("%-2.2d" % (@starting_bay_number.to_i + i), @connection)
        #  bay_controller.connect
        #  @bay_controllers << bay_controller
        #end
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
        msg_hash.merge!({:fields => {:number_of_d4 => @d4_list.size,
                                     :number_of_lp => @lp_list.size,
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
    end
  end
end

