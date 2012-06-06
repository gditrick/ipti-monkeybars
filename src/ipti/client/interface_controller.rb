module IPTI
  module Client
    class InterfaceController < IPTI::Controller
      attr_accessor :version, :bay_polling, :number_of_bays, :starting_bay_number, :bay_controllers

      message_type :heartbeat,    :code => "01"
      message_type :set_bays,     :code => "02", :response_handler => :get_set_number_of_bays, :formatter => :format_number_bays
      message_type :bay_status,   :code => "03"
      message_type :set_polling,  :code => "81", :response_handler => :get_set_bay_polling, :formatter => :format_bay_polling
      message_type :version,      :code => "97", :response_handler => :get_version, :formatter => :format_version
      message_type :reset,        :code => "99", :response_handler => :reset

      def initialize(address, connection=nil)
        @version     = "PM-Simulate-0.0.1"
        @bay_polling = "false"
        super
        InterfaceController.instances[IPTI::Controller.key(address, connection)] = self
      end

      def connect_comm
        @in_queue   = EventMachine::Queue.new
        @out_queue  = EventMachine::Queue.new
        @in_queue_mutex  = Mutex.new
        @out_queue_mutex = Mutex.new
        @in_timer        = EM::PeriodicTimer.new(0.01) { process_in_queue }
        @out_timer       = EM::PeriodicTimer.new(0.01) { process_out_queue }
        @bay_controllers = []
        @number_of_bays  = @connection.app.light_bar.bays.size
        @starting_bay_number = @connection.app.light_bar.bays[0].address
        (0...@number_of_bays).each do |i|
          bay_controller = IPTI::Client::BayController.new("%-2.2d" % (@starting_bay_number.to_i + i), @connection)
          bay_controller.connect
          @bay_controllers << bay_controller
        end
      end

      def disconnection
        @in_queue  = nil
        @out_queue = nil
        @in_timer.cancel
        @in_timer  = nil
        @out_timer.cancel
        @out_timer = nil
      end

      def get_set_number_of_bays(msg_hash)
        msg = msg_hash[:msg]
        if msg.size > 6    #keep this part to show the set part although server is not sending a set as of now
          self.number_of_bays      = msg.slice(4,2).to_i
          self.starting_bay_number = msg.slice(6,2).to_i
          @bay_controllers ||= []
          (self.starting_bay_number...(self.number_of_bays + self.number_of_bays)).each do |bay_addr|
            bay_controller = IPTI::Client::BayController.new("%2.2d" % bay_addr, self.connection)
            @bay_controllers << bay_controller
          end
        else
          msg_hash.merge!({:fields => {:number_of_bays => self.number_of_bays,
                                       :starting_bay_number => self.starting_bay_number,
                                       :ack => true}
                          })
          self.ack
        end
      end

      def format_number_bays(args=nil)
        return '' if args.nil?
        "%-2.2d%-2.2d" % [ args[0][:number_of_bays], args[0][:starting_bay_number]]
      end

      def get_set_bay_polling(msg_hash)
        msg = msg_hash[:msg]
        if msg.size > 6
          self.bay_polling = msg.slice(4,1) == "1" ? true : false
          msg_hash.merge!({:fields => {:ack => true}})
          bay_polling_msg = self.message_types[:set_polling].message(self, nil, {:ack => true})
        else
          msg_hash.merge!({:fields => {:bay_polling => self.bay_polling, :ack => true}})
          bay_polling_msg = self.message_types[:set_polling].message(self, nil, msg_hash[:fields])
        end
        self.ack
        bay_polling_msg
      end

      def format_bay_polling(args=nil)
        return '' if args.nil?
        return '' if args[0][:bay_polling].nil?
        format_true_false(args[0][:bay_polling])
      end

      def get_version(msg_hash)
pp "Get version"
pp msg_hash
        version_msg = self.message_types[:version].message(self)
        msg_hash.merge!({:fields => {:ack => true}})
        self.ack
        version_msg
      end

      def format_version(args=nil)
        self.version
      end

      def reset(msg)
        reset_msg =  self.message_types[:reset].message(self)
        reset_msg
      end
    end
  end
end
