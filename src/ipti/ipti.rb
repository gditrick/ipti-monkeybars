require 'eventmachine'
require 'state_machine'
require 'pp'

module IPTI
  class PickMaxMessageType
    attr_accessor :type, :code, :response_handler, :formatter

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
      end
    end

    def message(controller, *fields)
      if @formatter
        pp @formatter
        pp "fields:"
        pp fields
        data = fields.flatten.compact.empty? ? controller.send(@formatter) : controller.send(@formatter, fields)
      elsif fields.flatten.compact.empty?
        data = ''
      else
        data = fields.flatten.compact.inject('') {|d,o| d += o }
      end

      controller.seq.to_s == '' ? controller.address.to_s + @code.to_s + data : controller.address.to_s + controller.seq + @code.to_s + data
    end

    def process_message(controller, msg)
      if @response_handler
        controller.send(@response_handler, msg)
      else
        process_ack(controller, msg)
      end
    end

    def process_ack(controller, msg)
      ack_msg = controller.address == 'EF' ?
        controller.address + @code + "\006" :
          controller.address + controller.seq.to_s + @code + "\006"

      ack_msg += PickMaxProtocol.check_sum(ack_msg)
      msg == ack_msg
    end

    def response(ctl, msg_hash)
      if @response_handler
        ctl.send(@response_handler, msg_hash)
      else
        ack_response(msg_hash[:msg])
      end
    end

    def ack_response(msg)
      (msg =~ /:/).nil? ? msg.slice(0,2) + @code.to_s + "\006" : msg.slice(0,5) + @code.to_s + "\006"
    end
  end

  class Controller
    include EventMachine::Deferrable

    attr_accessor :instances, :address, :connection, :seq, :message, :out_queue, :in_queue

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
      @seq        = ""
      @address    = address
      @connection = connection
      Controller.instances[Controller.key(address, connection)] = self
    end

    def bump_seq
    end

    def push_in_msg(msg_hash)
      @in_queue_mutex.synchronize do
        @in_queue.push msg_hash
      end
    end

    def process_in_queue
      @in_queue_mutex.synchronize do
        unless @in_queue.empty?
          @in_queue.pop do |msg_hash|
            self.processing_request
            process_message(msg_hash)
          end
        end if self.idle?
      end
    end

    def push_out_msg(msg, type, msg_hash)
      @out_queue_mutex.synchronize do
        @out_queue.push({:msg => msg, :type => type, :seq => @seq}.merge(msg_hash))
      end
    end

    def process_out_queue
      @out_queue_mutex.synchronize do
        unless @out_queue.empty?
          @out_queue.pop do |msg_hash|
            @connection.push_out_msg({:data => msg_hash[:msg],
                                      :type => msg_hash[:type],
                                      :controller => self,
                                      :fields => msg_hash[:fields]
            })
            self.bump_seq
          end
        end
      end
    end

    def process_message(msg_hash)
      m_type = self.message_types[msg_hash[:code].to_sym]
pp m_type
pp "IN -> #{self.address}:#{self.state_name}"
      response_msg = m_type.response(self, msg_hash)
      push_out_msg(response_msg, m_type, msg_hash)
    end

    def is_a_ipti_interface_controller?
      self.is_a?(IptiInterfaceController)
    end

    def self.message_type(type, opts = {}, &block)
      @message_types ||= {}
      m_type = IPTI::PickMaxMessageType.new(type, opts, &block)
      @message_types[type.to_sym]        = m_type
      @message_types[m_type.code.to_sym] = m_type
      define_attr_method(:message_types, @message_types)
    end

    def format_true_false(arg=nil)
      return "'" if arg.nil? or arg.empty?
      pp "arg #{arg}"
      arg == true ? "1" : "0"
    end

    def self.define_attr_method(name, value)
      send :define_method, name do
        value
      end
    end
  end
end