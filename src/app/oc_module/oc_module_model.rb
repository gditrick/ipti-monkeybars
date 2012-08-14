class OcModuleModel < AbstractModel
  attr_accessor :address,
                :blink,
                :bus,
                :controller_klass,
                :controller,
                :down_state,
                :fast_blinkers,
                :fast_blink_count,
                :led_color,
                :led_state,
                :main_oc,
                :scroll_text,
                :scroll_index,
                :slow_blinkers,
                :slow_blink_count,
                :task_state,
                :text,
                :type_sym,
                :up_state

  def initialize(addr="01")
    @address          = addr
    @controller_klass = 'OcModuleController'
    @text             = ''
    @led_state        = :off
    @up_state         = :off
    @down_state       = :off
    @type_sym         = :oc
  end

  def to_yaml_properties
    ["@address", "@controller_klass", "@main_oc", "@type_sym"]
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
            when :oc_display then
              display_text(message.bytes)
              @controller.activate_module(self)
            when :cancel_order
              @controller.cancel
            else
              raise "Unknown OC Message Type #{message.message_type.type}"
          end
        end
      end
    end
  end

  def blink?
    @blink
  end

  private

  def display_text(msg)
    led_states    = msg.slice(9,1)
    control_byte  = msg.slice(10,1).hex
    text          = msg.slice(11..-3)
    text.slice!(29..-1)

    @scroll_text  = nil
    @scroll_index = 0
    @blink        = false

    @fast_blinkers = []
    @slow_blinkers = []

    @fast_blink_count = 0
    @slow_blink_count = 0

    if text.size > 12
      @text        = "            "
      @scroll_text = "         " + text
    else
      @text        = text
    end

    case led_states
      when "0" then
        @led_color  = :light_gray
        @led_state  = :off
        @task_state = :off
      when "1" then
        @led_state  = :fast
        @task_state = :on
        @fast_blinkers << :led
      when "2" then
        @led_state  = :slow
        @task_state = :on
        @slow_blinkers << :led
      when "3" then
        @led_color  = :deep_sky_blue
        @led_state  = :on
        @task_state = :on
    end

    if control_byte & 1 == 1
      @task_state = :on
    else
      @task_state = :off
    end

    if control_byte & 2 == 2
      @up_state = :on
    else
      @up_state = :off
    end

    if control_byte & 4 == 4
      @down_state = :on
    else
      @down_state = :off
    end

    @blink = true unless @slow_blinkers.empty? and @fast_blinkers.empty?
  end
end
