require 'eventmachine'
require 'state_machine'
require 'pp'

module IPTI
  class PickMaxMessageType
    attr_accessor :type, :code, :response_handler, :formatter, :ack_handler

    def initialize(type, *args)
      @type = type
      args.each do |arg|
        @code = arg[:code] if arg[:code]
        if arg[:response_handler]
          @response_handler = arg[:response_handler]
        end
        if arg[:formatter]
          @formatter = arg[:formatter]
        end
        if arg[:ack_handler]
          @ack_handler = arg[:ack_handler]
        end
      end
    end
  end

  class PickMaxMessage
    attr_accessor :controller, :message_type, :bytes, :track, :sequence, :fields, :response_required

    def initialize(controller, message_type, track=nil, bytes=nil)
      @controller        = controller
      @message_type      = message_type
      @response_required = false
      @track             = track
      @bytes             = bytes
      @fields            = {}
    end

    def response_required?
      @response_required
    end

    def process_message
      if @message_type.response_handler
        @controller.send(@message_type.response_handler, self)
      else
        process_ack
      end
    end

    def process_ack
      if @message_type.ack_handler
        ack_msg = @controller.send(@message_type.ack_handler, self)
      else
        ack_msg = @controller.address == 'EF' ?
            @controller.address + @message_type.code + "\006" :
            @controller.address + ("%2.2d" % @sequence) + ':' + @message_type.code + "\006"
        ack_msg += IPTI::PickMaxProtocol.check_sum(ack_msg)
      end

      @bytes == ack_msg
    end

    def response
      if @message_type.response_handler
        @controller.send(@message_type.response_handler, self)
      else
        ack_response
      end
    end

    def format
      if @message_type.formatter
        data = @fields.empty? ?
            @controller.send(@message_type.formatter) :
            controller.send(@message_type.formatter, @fields)
      elsif @fields.empty?
        data = ''
      else
        data = @fields.inject('') {|d,(k,v)| d += v }
      end

      ack = (@fields.empty? or @fields[:ack].nil?) ? '' :
          @fields[:ack] ? "\006" : ''

      data += ack

      @bytes = @controller.address == 'EF' ?
          @controller.address + @message_type.code + data :
          @controller.address + ("%2.2d" % @sequence) + ':' + @message_type.code + data

      @bytes += IPTI::PickMaxProtocol.check_sum(@bytes)
    end

    def is_ack?
      return false if @bytes.nil?
      (@bytes =~ /\006/) == nil ? false : true
    end

    def ack_response
      (@bytes =~ /:/).nil? ?
          @bytes.slice(0,2) + @message_type.code.to_s + "\006" :
          @bytes.slice(0,5) + @message_type.code.to_s + "\006"
    end
  end

  class ResponseTracker
    attr_accessor :controller, :message

    def initialize(controller, message)
       @controller = controller
       @message    = message
    end

    def run
      @timer = EM::Timer.new(1) { @controller.connection.send_data(@message)}
    end

    def cancel
      @timer.cancel
      @controller.response_received
    end
  end

  class Controller
    include EventMachine::Deferrable

    attr_accessor :instances, :address, :connection, :seq, :message,
                  :out_queue, :in_queue, :processing_out, :processing_in,
                  :state_mutex

    state_machine :state, :initial => :no_comm do
      after_transition [:idle] => :no_comm, :do => :disconnection
      after_transition :no_comm => :idle, :do => :connect_comm

      around_transition do |ctl, transition, block|
        ctl.state_mutex.synchronize do
          block.call
        end
      end

      event :connect do
        transition :no_comm => :idle
      end

      event :disconnect do
        transition [:idle, :waiting_for_response] => :no_comm
      end

      event :wait_for_response do
        transition :idle => :waiting_for_response
      end

      event :response_received do
        transition :waiting_for_response => :idle
      end
    end

    def self.instances
      @instances ||= {}
      @instances
    end

    def self.key(address, connection=nil)
      if connection.nil?
        address.to_s
      else
        connection.ip.to_s + ":" + connection.port.to_s + ':' + address.to_s
      end
    end

    def initialize(address, connection=nil)
      @seq             = ""
      @address         = address
      @connection      = connection
      @state_mutex     = Mutex.new
      @in_queue_mutex  = Mutex.new
      @out_queue_mutex = Mutex.new
      super()
      Controller.instances[Controller.key(address, connection)] = self
    end

    def bump_seq
    end


    def push_in_msg(message)
      unless @in_queue.nil?
        @in_queue_mutex.synchronize do
          @in_queue.push message
        end
        EM::schedule { process_in_queue }
      end
    end

    def process_in_queue
      unless @in_queue.nil?
        @in_queue_mutex.synchronize do
          until @in_queue.empty? do
            @in_queue.pop do |message|
              if self.waiting_for_response?
                if message.track == @response_tracker.message.track
                  bump_seq
                  @response_tracker.cancel
                  process_response(message)
                else
                  process_message(message)
                end
              elsif self.idle?
                process_message(message)
              else
                raise "Controller: #{self.address} in a bad state: #{self.state_name}"
              end
            end
          end
        end
      end
    end

    def push_out_msg(message)
      @out_queue_mutex.synchronize do
        @out_queue.push(message)
      end
      EM::schedule { process_out_queue }
    end

    def process_out_queue
      @out_queue_mutex.synchronize do
        until @out_queue.empty? do
          @out_queue.pop do |message|
            @connection.push_out_msg(message)
          end
        end
      end
    end

    def process_message(message)
      response = message.response
      push_out_msg(response) unless response.nil?
    end

    def process_response(message)
      if message.is_ack?
        message.process_ack
      else
        message.process_message
      end
    end

    def format_true_false(arg=nil)
      return "0'" if arg.nil?
      arg == true ? "1" : "0"
    end

    def self.message_type(type, opts = {}, &block)
      @message_types ||= {}
      m_type = IPTI::PickMaxMessageType.new(type, opts, &block)
      @message_types[type.to_sym]        = m_type
      @message_types[m_type.code.to_sym] = m_type
      define_attr_method(:message_types, @message_types)
    end

    def self.define_attr_method(name, value)
      send :define_method, name do
        value
      end
    end

    def track_response(message)
      @response_tracker = IPTI::ResponseTracker.new(self, message)
      @response_tracker.run
      self.wait_for_response
    end
  end
end