class LtModuleModel < AbstractModel
  attr_accessor :address,
                :blink,
                :bus,
                :controller_klass,
                :controller,
                :fails,
                :fail_rate,
                :scroll_text,
                :scroll_index,
                :text,
                :type_sym

  def initialize(addr="01")
    @address          = addr
    @controller_klass = 'LtModuleController'
    @fails            = false
    @fail_rate        = 0
    @text             = ''
    @type_sym         = :lt
  end

  def to_yaml_properties
    ["@address", "@controller_klass", "@type_sym", "@fail_rate"]
  end

  def ==(other)
    @address == other.address and
      @controller_klass == other.controller_klass
  end

  def bus=comm_bus
    @bus       = comm_bus
    @in_mutex  = Mutex.new
    @in_queue  = EM::Queue.new
  end

  def push_msg(msg)
    @in_mutex.synchronize do
      @in_queue.push msg
    end
    EM::schedule { process_in_queue }
  end

  def process_in_queue
    @in_mutex.synchronize do
      unless @in_queue.empty?
        @in_queue.pop do |message|
          case message.message_type.type
            when :lt_display then
              display_text(message.bytes)
              @controller.activate_module(self) if self.worked?
            else
              raise "Unknown LT Message Type #{message.message_type.type}"
          end
        end
      end
    end
  end

  def blink?
    @blink
  end

  def fail?
    @fails = rand(100) < (@fail_rate.nil? ? 0 : @fail_rate)
  end

  def failed?
    @fails
  end

  def worked?
    not @fails
  end

  private

  def display_text(msg)
    text          = msg.slice(9..-3)
    text.slice!(29..-1)

    return if fail?

    @scroll_text  = nil
    @scroll_index = 0

    if text.size > 12
      @text        = "            "
      @scroll_text = "         " + text
    else
      @text        = text
    end
  end
end
