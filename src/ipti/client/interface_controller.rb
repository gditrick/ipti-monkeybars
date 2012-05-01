require 'state_machine'

module IPTI
  module Client
    class InterfaceController < IPTI::Controller
      attr_accessor :version, :bay_polling, :number_of_bays, :starting_bay_number, :bay_controllers

      message_type :heartbeat,    :code => "01"
      message_type :set_bays,     :code => "02", :response_handler => :set_number_of_bays
      message_type :bay_status,   :code => "03"
      message_type :set_polling,  :code => "81", :response_handler => :get_set_bay_polling, :formatter => :format_bay_polling
      message_type :version,      :code => "97", :response_handler => :get_version, :formatter => :version
      message_type :reset,        :code => "99", :response_handler => :reset

      state_machine :state, :initial => :no_comm do
        after_transition [:idle] => :no_comm, :do => :disconnection
        after_transition :no_comm => :idle, :do => :connect_comm

        event :connect do
          transition :no_comm => :idle
        end

        event :disconnect do
          transition [:idle, :send_response] => :no_comm
        end

        event :ack do
          transition [:send_response, :idle] => :send_ack
        end

        event :processing_request do
          transition :idle => :send_response
        end

        event :processed_request do
          transition [:send_response, :send_ack] => :idle
        end
      end

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
      end

      def disconnection
        @in_queue  = nil
        @out_queue = nil
        @in_timer.cancel
        @in_timer  = nil
        @out_timer.cancel
        @out_timer = nil
      end

      def get_number_of_bays(msg)
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

      def get_set_bay_polling(msg_hash)
        self.ack
        msg = msg_hash[:msg]
        if msg.size > 6
pp "Setting Bay Polling"
          self.bay_polling = msg.slice(4,1) == "1" ? true : false
          bay_polling_msg = self.message_types[:set_polling].message(self)
        else
pp "Query Bay Polling"
msg_hash.merge!({:fields => {:bay_polling => self.bay_polling}})
          bay_polling_msg = self.message_types[:set_polling].message(self, msg_hash[:fields])
        end
        bay_polling_msg
      end

      def get_version(msg)
        self.ack
        version_msg = self.message_types[:version].message(self)
        version_msg
      end

      def format_bay_polling(args)
pp "format_bay_polling"
pp args[0]
        format_true_false(args[0][:bay_polling])
      end

      def reset(msg)
        reset_msg =  self.message_types[:reset].message(self)
pp msg
pp reset_msg
pp (msg == reset_msg)
        reset_msg
      end
    end
  end
end
