require 'eventmachine'
require 'pp'
require 'ipti/protocols'

module IPTI
  module Client
    class PickMaxProtocol < EventMachine::Connection
      include IPTI::PickMaxProtocol

      def post_init
        pp "Establish connection to server"
      end
    end
  end
end
