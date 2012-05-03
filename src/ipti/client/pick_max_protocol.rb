require 'eventmachine'
require 'state_machine'
require 'pp'
require 'ipti/protocols'

module IPTI
  module Client
    class CommunicationBus
      def initialize
        @comm_mutex  = Mutex.new
        @comm_queue  = EventMachine::Queue.new
      end

      def push_bus_msg(bus_msg)
        @comm_mutex.synchronize do
          @comm_queue.push bus_msg
        end
      end

      def pop_bus_msg
        bus_msg = nil
        @comm_mutex.synchronize do
          unless @comm_queue.empty?
            @comm_queue.pop{|a| bus_msg = a}
          end
        end
        bus_msg
      end
    end

    class BusMessage
      attr_accessor :code, :fields
    end

    class PickMaxProtocol < EventMachine::Connection
      include IPTI::PickMaxProtocol

      state_machine :state, :initial => :not_connected do
        after_transition :not_connected => :connected, :do => :connection
#
        event :connect do
          transition :not_connected => :connected
        end
      end
    end
  end
end
