require 'eventmachine'
require 'pp'

module IPTI
  module PickMaxProtocol
    attr_reader :data_received, :port, :ip, :app,
                :in_queue, :out_queue,
                :processing_in, :processing_out

    def initialize(app)
      @app = app
      @app.connected = false
      @data_received = ""
      @in_queue      = nil
      @out_queue     = nil
      super
    end

    def receive_data(data)
pp "data received: " + data
      @data_received << data
      @data_received.split(/[\001\003]/).each do |msg|
        next if msg.size == 0
pp " msg received: " + msg
        @in_queue_mutex.synchronize do
          @in_queue.push msg
        end
        @data_received.slice!("\001" + msg + "\003")
        @data_received.lstrip!
pp "remaining data: " + @data_received
      end
      EM::schedule { process_in_queue }
    end

    def connection_completed
pp "Establish connection to server"
      self.connect
    end

    def unbind
pp "Connection closed to server" if @app.connected?
      @in_timer.cancel unless @in_timer.nil?
      @out_timer.cancel unless @out_timer.nil?
      @app.connected = false
      @data_received = ""
      @in_queue      = nil
      @out_queue     = nil
    end

    def connection
      controller = IPTI::Controller.instances[IPTI::Controller.key('EF')]
      IPTI::Controller.instances.delete(IPTI::Controller.key('EF'))
      @app.connected = true
      @port, @ip = Socket.unpack_sockaddr_in(get_peername)
      @app.interface_controller = IPTI::Client::InterfaceController.new('EF', self)
      @app.interface_controller.connect
      @app.light_bar.bays do |bay|
        bay.bay_controller = IPTI::Client::BayController.new(bay.address, self)
#        bay.bay_controller.connect
      end
      @data_received   = ""
      @data_received   = ""
      @in_queue        = EM::Queue.new
      @in_queue_mutex  = Mutex.new
      @out_queue       = EM::Queue.new
      @out_queue_mutex = Mutex.new
    end

    def push_out_msg(msg_hash)
      @out_queue_mutex.synchronize do
        @out_queue.push msg_hash
      end
      EM::schedule { process_out_queue }
    end

    def process_out_queue
      @out_queue_mutex.synchronize do
        until @out_queue.empty? do
          @out_queue.pop do |message|
            send_data(message)
          end
        end
      end
    end

    def process_in_queue
      @in_queue_mutex.synchronize do
        until @in_queue.empty? do
          @in_queue.pop{|msg| process_message(msg)}
        end
      end
    end

    def process_message(msg)
      (msg =~ /:/).nil? ? process_msg(msg) : process_seq_msg(msg)
    end

    def process_msg(msg)
      addr = msg.slice(0,2)
      code = msg.slice(2,2)
      message_handler(msg, code, addr)
    end

    def process_seq_msg(msg)
      addr = msg.slice(0,2)
      seq  = msg.slice(2,2)
      code = msg.slice(5,2)
      message_handler(msg, code, addr, seq)
    end

    def message_handler(msg, code, addr, seq=nil)
      controller = IPTI::Controller.instances[IPTI::Controller.key(addr, self)]
      message_type = controller.message_types[code.to_sym]
      if message_type.nil?
        raise "Message Type #{code} not implemented for Controller: #{controller.address}"
      end
      case controller
        when IPTI::Client::InterfaceController then
          message = IPTI::PickMaxMessage.new(controller, message_type, code, msg)
        when IPTI::Client::BayController then
          message = IPTI::PickMaxMessage.new(controller, message_type, seq.to_i, msg)
          message.sequence = seq.to_i
      end
      controller.push_in_msg(message)
    end

    def send_data(message)
      data  = message.format
      msg   = "\001"
      msg  += data
      msg  += "\003"
pp "send: " + msg
      message.controller.track_response(message) if message.response_required?
      super msg
    end

    def self.check_sum(data)
      ("%2.2x" % data.bytes.inject(0){|sum,c| sum += c}).slice(-2,2).upcase
    end
  end
end