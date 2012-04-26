require 'eventmachine'
require 'pp'
require 'ipti/protocols'

module IPTI
  module Client
    class PickMaxProtocol < EventMachine::Connection
      attr_accessor :instances, :ip, :port

      include IPTI::PickMaxProtocol

      def self.instances
        @instances ||= {}
        @instances
      end

      def post_init
      end
    end
  end
end
