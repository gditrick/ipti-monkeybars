require 'eventmachine'
require 'state_machine'
require 'pp'

module IPTI
  class PickMaxMessageType
    attr_accessor :type, :code, :response_handler

    def initialize(type, *args)
      @type = type
      args.each do |arg|
        @code = arg[:code] if arg[:code]
        if arg[:response_handler]
          @response_handler = arg[:response_handler]
        end
      end
    end

    def message(address, seq, fields={})
      data = fields.empty? ? '' : field_formatter(fields)
      seq.to_s == '' ? address.to_s + @code.to_s + data : address.to_s + seq + @code.to_s + data
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

    def ack_response(msg)
      (msg =~ /:/).nil? ? msg.slice(0,2) + @code.to_s + "\006" : msg.slice(0,5) + @code.to_s + "\006"
    end
  end

  class Controller
    include EventMachine::Deferrable

    attr_accessor :instances, :address, :connection, :seq, :message, :out_queue, :in_queue

    state_machine :state, :initial => :connected do
      after_transition :connected => :initializing, :do => :boot
      after_transition :waiting => :resetting, :do => :boot

      after_failure :on => [:reply_processed, :receive_request], :do => :resend

      event :starting do
        transition :connected => :initializing
      end

      event :reset_completed do
        transition :waiting => :resetting
      end

      event :send_request do
        transition [:waiting, :resetting] => :waiting_for_reply
        transition :initializing => :waiting_for_reply, :if => :is_a_ipti_interface_controller?
        transition :initializing => :waiting, :unless => :is_a_ipti_interface_controller?
      end

      event :reply_processed do
        transition :waiting_for_reply  => :waiting
      end

      event :receive_request do
        transition :waiting  => :processing_request
      end

      event :request_processed do
        transition :processing_request => :waiting
      end

      state :connected do
      end

      state :initializing do
        def boot(sm)
          self.connection.send_data('', self.address, self.message_types[:reset])
          if self.is_a_ipti_interface_controller?
            self.connection.send_data('', self.address, self.message_types[:version])
            self.connection.send_data('', self.address, self.message_types[:set_polling])
            self.connection.send_data('', self.address, self.message_types[:set_bays])

#            tmp_msg = self.message_types[:set_bays].message(self.address, self.seq)
#            tmp_msg += '0101'
#            self.connection.send_data(tmp_msg, self.address)
          end
        end
      end

      state :resetting do
        def boot(sm)
          self.connection.send_data('', self.address, self.message_types[:set_num_of_devices])
        end
      end

      state :waiting do
      end

      state :waiting_for_reply do
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
      @in_queue   = EventMachine::Queue.new
      @out_queue  = EventMachine::Queue.new
      Controller.instances[Controller.key(address, connection)] = self
      super()
    end

    def bump_seq
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

    def self.define_attr_method(name, value)
      send :define_method, name do
        value
      end
    end
  end
end