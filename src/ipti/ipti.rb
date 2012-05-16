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

    def message(controller, *fields)
      if @formatter
        data = fields.flatten.compact.empty? ? controller.send(@formatter) : controller.send(@formatter, fields)
      elsif fields.flatten.compact.empty?
        data = ''
      else
        data = fields.flatten.compact.inject('') {|d,o| d += o }
      end

      controller.seq.to_s == '' ? controller.address.to_s + @code.to_s + data : controller.address.to_s + controller.seq + @code.to_s + data
    end

    def process_message(controller, msg_hash)
      if @response_handler
        controller.send(@response_handler, msg_hash)
      else
        process_ack(controller, msg_hash)
      end
    end

    def process_ack(controller, msg_hash)
      if @ack_handler
        data = controller.send(@ack_handler, msg_hash)
        ack_msg = controller.address == 'EF' ?
            controller.address + msg_hash[:code] + data + "\006" :
            controller.address + msg_hash[:seq].to_s + ':' + msg_hash[:code] + data + "\006"
      else
        ack_msg = controller.address == 'EF' ?
          controller.address + msg_hash[:code] + "\006" :
            controller.address + msg_hash[:seq].to_s + ':' + msg_hash[:code] + "\006"
      end

      ack_msg += IPTI::PickMaxProtocol.check_sum(ack_msg)

      msg_hash[:msg] == ack_msg
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

    state_machine :state, :initial => :no_comm do
      after_transition [:idle] => :no_comm, :do => :disconnection
      after_transition :no_comm => :idle, :do => :connect_comm

      event :connect do
        transition :no_comm => :idle
      end

      event :disconnect do
        transition [:idle, :send_response] => :no_comm
      end

      event :ack do
        transition [:send_response, :idle] => :send_ack
      end

      event :wait_for_ack do
        transition all => :waiting_for_ack
      end

      event :processing_ack do
        transition :waiting_for_ack => :ack_processing
      end

      event :processed_ack do
        transition :ack_processing => :idle
      end

      event :processing_request do
        transition :idle => :send_response
      end

      event :processed_request do
        transition [:send_response, :send_ack] => :idle
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
      @seq        = ""
      @address    = address
      @connection = connection
      super()
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
pp "RECV IN -> #{self.address}:#{self.state_name}"
          @in_queue.pop do |msg_hash|
            case self.state_name
              when :idle then
                self.processing_request
                process_message(msg_hash)
              when :waiting_for_ack then
                self.processing_ack
                process_ack(msg_hash)
            end
          end
        end if self.idle? or self.waiting_for_ack?
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
            self.bump_seq unless self.waiting_for_ack?
          end
        end
      end
    end

    def process_message(msg_hash)
      m_type = self.message_types[msg_hash[:code].to_sym]
      if m_type.nil?
        raise "Message Type #{msg_hash[:code]} not implemented"
      else
        msg_hash.merge!({:type => m_type})
        response_msg = m_type.response(self, msg_hash)
        push_out_msg(response_msg, m_type, msg_hash)
      end
    end

    def process_ack(msg_hash)
      m_type = self.message_types[msg_hash[:code].to_sym]
      msg_hash.merge!({:type => m_type})
      self.processed_ack if m_type.process_ack(self, msg_hash)
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
      return "0'" if arg.nil?
      arg == true ? "1" : "0"
    end

    def self.define_attr_method(name, value)
      send :define_method, name do
        value
      end
    end
  end
end