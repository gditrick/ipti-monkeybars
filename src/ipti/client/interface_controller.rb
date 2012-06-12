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
        @bay_polling = true
        super
        InterfaceController.instances[IPTI::Controller.key(address, connection)] = self
      end

      def connect_comm
        @in_queue   = EventMachine::Queue.new
        @out_queue  = EventMachine::Queue.new
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
        @in_queue_mutex.synchronize do
          @in_queue  = nil
        end
        @out_queue_mutex.synchronize do
          @out_queue = nil
        end
      end

      def get_set_number_of_bays(message)
        bays_msg = IPTI::PickMaxMessage.new(self, self.message_types[:set_bays])
        if message.bytes.size > 6    #keep this part to show the set part although server is not sending a set as of now
          self.number_of_bays      = bytes.slice(4,2).to_i
          self.starting_bay_number = bytes.slice(6,2).to_i
          @bay_controllers ||= []
          (self.starting_bay_number...(self.number_of_bays + self.number_of_bays)).each do |bay_addr|
            bay_controller = IPTI::Client::BayController.new("%2.2d" % bay_addr, self.connection)
            @bay_controllers << bay_controller
          end
        else
          bays_msg.fields[:number_of_bays] = self.number_of_bays
          bays_msg.fields[:starting_bay_number] = self.starting_bay_number
        end
        bays_msg.fields[:ack] = true
        bays_msg
      end

      def format_number_bays(args={})
        return '' if args.empty?
        return '' if args[:number_of_bays].nil? or args[:starting_bay_number].nil?
        "%-2.2d%-2.2d" % [args[:number_of_bays], args[:starting_bay_number]]
      end

      def get_set_bay_polling(message)
        if message.bytes.size > 6
          bay_polling_msg = IPTI::PickMaxMessage.new(self, self.message_types[:set_polling])
          self.bay_polling = message.bytes.slice(4,1) == "1" ? true : false
          bay_polling_msg.fields[:ack] = true
        else
          bay_polling_msg = IPTI::PickMaxMessage.new(self, self.message_types[:set_polling])
          bay_polling_msg.fields[:bay_polling] = self.bay_polling
          bay_polling_msg.fields[:ack] = true
        end
        bay_polling_msg
      end

      def format_bay_polling(args={})
        return '' if args.empty?
        return '' if args[:bay_polling].nil?
        format_true_false(args[:bay_polling])
      end

      def get_version(message)
        version_msg = IPTI::PickMaxMessage.new(self, self.message_types[:version])
        version_msg.fields[:version] = self.version
        version_msg.fields[:ack] = true
        version_msg
      end

      def format_version(args={})
        return '' if args.empty?
        args[:version]
      end

      def reset(message)
        IPTI::PickMaxMessage.new(self, self.message_types[:reset])
      end
    end
  end
end
