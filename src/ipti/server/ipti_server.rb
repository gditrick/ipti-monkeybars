require "eventmachine"

Dir.glob(File.dirname(__FILE__) + '../**/*.rb').each{|f| require(f) }

EventMachine::run {
  EventMachine::start_server("192.168.1.31", 2000, IPTI::PickMaxProtocol)
  puts "Listening......"
}