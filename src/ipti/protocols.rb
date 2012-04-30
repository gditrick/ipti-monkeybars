require 'eventmachine'
require 'state_machine'
require 'pp'

module IPTI
  module PickMaxProtocol
    attr_reader :data_received, :in_queue, :out_queue, :port, :ip

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
      @app.connected = true
      @port, @ip = Socket.unpack_sockaddr_in(get_peername)
      @data_received   = ""
      @in_queue        = EM::Queue.new
      @in_queue_mutex  = Mutex.new
      @out_queue       = EM::Queue.new
      @out_queue_mutex = Mutex.new
      @in_timer        = EM::PeriodicTimer.new(0.01) { process_in_queue }
      @out_timer       = EM::PeriodicTimer.new(0.01) { process_out_queue }
    end

    def push_out_msg(msg)
      @out_queue_mutex.synchronize do
        @out_queue.push msg
      end
    end

    def process_out_queue
      @out_queue_mutex.synchronize do
        unless @out_queue.empty?
          @out_queue.pop{|msg| send_data(msg)}
        end
      end
    end

    def process_in_queue
      @in_queue_mutex.synchronize do
        unless @in_queue.empty?
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
      controller.push_in_msg(msg)
    end
#      m_type = controller.message_types[code.to_sym]
#  pp "IN -> #{controller.address}:#{controller.state_name}"
#      case controller.state_name
#        when :processing_request
#          controller.in_queue.push{|q| msg }
#        when :waiting
#          controller.receive_request
#          send_data(m_type.ack_response(msg), controller.address)
#          if m_type.process_message(controller, msg)
#            controller.bump_seq
#            controller.request_processed
#          end
#        when :waiting_for_reply
#          if m_type.process_message(controller, msg)
#            controller.bump_seq
#            controller.reply_processed
#          end
#        else
#          raise "Controller state invalid: #{controller.state}"
#      end
#pp "OUT -> #{controller.address}:#{controller.state_name}"
#      check_queues
#    end

#    def send_data(data, address, message_type=nil, fields={})
#      controller = IPTI::Controller.instances[IPTI::Controller.key(self, address)]
#pp "IN -> #{controller.address}:#{controller.state_name}"
#pp controller
#      unless message_type.nil?
#        data = message_type.message(controller.address, controller.seq, fields)
#      end
#      msg = "\001" + data + PickMaxProtocol.check_sum(data) + "\003"
#      if controller.state_name == :waiting_for_reply
#        # Queue Message
#        controller.out_queue.push([data, address, message_type, fields])
#      else
#        controller.send_request
#pp "send: " + msg
#        super msg
#      end
#pp "OUT -> #{controller.address}:#{controller.state_name}"
#      check_queues
#    end

  def check_queues
      IPTI::Controller.instances.each do |key, controller|
        unless controller.in_queue.empty?
          if [:waiting, :waiting_for_reply].include?(controller.state_name)
            controller.in_queue.pop{|m| process_msg(m)}
          end
        end
        unless controller.out_queue.empty?
          if controller.state_name == :waiting
            controller.out_queue.pop{|q| send_data(*q)}
          end
        end
      end
    end

    def self.check_sum(data)
      ("%2.2x" % data.bytes.inject(0){|sum,c| sum += c}).slice(-2,2).upcase
    end
  end
end