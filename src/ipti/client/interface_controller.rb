module IPTI
  module Client
    class InterfaceController < IPTI::Controller
      attr_accessor :version, :bay_polling, :number_of_bays, :starting_bay_number, :bay_controllers

      message_type :heartbeat,    :code => "01"
      message_type :set_bays,     :code => "02", :response_handler => :set_number_of_bays
      message_type :bay_status,   :code => "03"
      message_type :set_polling,  :code => "81", :response_handler => :set_bay_polling
      message_type :version,      :code => "97", :response_handler => :set_version
      message_type :reset,        :code => "99", :response_handler => :reset_received

      def initialize(address)
        super(address)
        InterfaceController.instances[IPTI::Controller.key(address)] = self
      end

      def set_number_of_bays(msg)
        self.number_of_bays      = msg.slice(4,2).to_i
        self.starting_bay_number = msg.slice(6,2).to_i
        @bay_controllers ||= []
        (self.starting_bay_number...(self.number_of_bays + self.number_of_bays)).each do |bay_addr|
          bay_controller = IptiBayController.new("%2.2d" % bay_addr, self.connection)
          @bay_controllers << bay_controller
        end
        @bay_controllers.each do |bay_controller|
          bay_controller.starting
          EventMachine::add_periodic_timer(30) { self.connection.send_data '', bay_controller.address, bay_controller.message_types[:heartbeat] }
        end
      end

      def set_bay_polling(msg)
        self.bay_polling = msg.slice(4,1) == "1" ? true : false
      end

      def set_version(msg)
        self.version = msg.slice(4..-4)
      end

      def reset_received(msg)
        reset_msg =  self.message_types[:reset].message(self.address, self.seq)
        reset_msg += PickMaxProtocol.check_sum(reset_msg)
pp msg
pp reset_msg
pp (msg == reset_msg)
        msg == reset_msg
      end
    end
  end
end
