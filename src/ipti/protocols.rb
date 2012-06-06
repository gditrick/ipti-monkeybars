require 'eventmachine'
require 'state_machine'
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
      @in_timer      = nil
      @out_timer     = nil
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
        @data_received.delete!("\001" + msg + "\003")
        @data_received.lstrip!
      end
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
      @in_timer      = nil
      @out_timer     = nil
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
      @processing_in, @processing_out = false, false
      @in_timer        = EM::PeriodicTimer.new(0.01) { process_in_queue }
      @out_timer       = EM::PeriodicTimer.new(0.01) { process_out_queue }
    end

    def processing_in?
      @processing_in
    end

    def processing_out?
      @processing__out
    end

    def push_out_msg(msg_hash)
      @out_queue_mutex.synchronize do
        @out_queue.push msg_hash
      end
    end

    def process_out_queue
      @out_queue_mutex.synchronize do
        unless processing_out?
          @processing_out = true
          until @out_queue.empty? do
            @out_queue.pop do |msg_hash|
              send_data(msg_hash[:data], msg_hash[:controller], msg_hash[:seq], msg_hash[:type], msg_hash[:fields])
            end
          end
          @processing_out = false
        end
      end
    end

    def process_in_queue
      @in_queue_mutex.synchronize do
        unless processing_in?
          @processing_in = true
          until @in_queue.empty? do
            @in_queue.pop{|msg| process_message(msg)}
          end
          @processing_in = false
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
      controller.push_in_msg({:code => code, :msg => msg, :seq => seq})
    end

    def send_data(data, controller, seq=nil, message_type=nil, *fields)
pp "SEND -> #{controller.address}:#{controller.state_name}"
pp "message type:"
pp message_type
pp fields
      ack = fields[0].nil? ? nil : fields[0][:ack].nil? ? nil : "\006"
      data = message_type.nil? ? '' : message_type.message(controller, seq, *fields)
      data += ack unless ack.nil?
      msg   = "\001"
      msg  += data
      msg  += IPTI::PickMaxProtocol.check_sum(data)
      msg  += "\003"
      if controller.has_saved_state?
        controller.recover_state
      else
        case controller.state_name
          when :idle then
            controller.wait_for_ack
          else
            controller.processed_request
        end
      end
pp "send: " + msg
      super msg
    end

    def self.check_sum(data)
      ("%2.2x" % data.bytes.inject(0){|sum,c| sum += c}).slice(-2,2).upcase
    end
  end
end