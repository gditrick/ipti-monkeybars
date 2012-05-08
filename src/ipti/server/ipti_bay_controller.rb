module IPTI
  module Server
    class IptiBayController < IPTI::Controller
      attr_accessor :four_digit_modules, :light_pick_modules

      message_type :heartbeat,           :code => "01"
      message_type :verify_turn_all_on,  :code => "02", :response_handler => :verify_turn_on
      message_type :verify_turn_all_off, :code => "03", :response_handler => :verify_turn_off
      message_type :turn_one_on,         :code => "04"
      message_type :turn_one_off,        :code => "05"
      message_type :turn_all_on,         :code => "06"
      message_type :turn_all_off,        :code => "07"
      message_type :set_num_of_devices,  :code => "81", :response_handler => :set_modules
      message_type :reset,               :code => "99", :response_handler => :resetting

      def initialize(address, connection)
        super(address, connection)
        @seq = 1
        @four_digit_modules = []
        @light_pick_modules = []
        IptiBayController.instances[IPTI::Controller.key(connection, address)] = self
      end

      def seq
        ("%2.2d" % @seq).slice(-2,2) + ":"
      end

      def bump_seq
        @seq = @seq >= 100 ?  0 : @seq + 1
      end

      def resetting(msg)
        reset_msg =  self.message_types[:reset].message(self.address, "99:")
        reset_msg += PickMaxProtocol.check_sum(reset_msg)
        if msg == reset_msg
          @seq = msg.slice(2,2).to_i
          self.request_processed
          self.reset_completed
        end
        msg == reset_msg
      end

      def set_modules(msg)
        @four_digit_modules = []
        @light_pick_modules = []
        num_of_modules   = msg.slice(7,2).to_i  # number of four digit modules
        starting_address = msg.size >= 12 ? msg.slice(11,2).to_i : 1
        (starting_address...(starting_address+num_of_modules)).each do |addr|
          @four_digit_modules << FourDigitModule.new("%2.2d" % addr)
        end
        num_of_modules   = msg.slice(9,2).to_i  # number of four digit modules
        starting_address = msg.size >= 14 ? msg.slice(14,2).to_i : 1
        (starting_address...(starting_address+num_of_modules)).each do |addr|
          @light_pick_modules << LightPickModule.new("%2.2d" % addr)
        end
      end
    end
  end
end
