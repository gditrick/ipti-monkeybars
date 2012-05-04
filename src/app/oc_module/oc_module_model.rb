class OcModuleModel < AbstractModel
  attr_accessor :address,
                :controller_klass,
                :controller,
                :text,
                :led_state,
                :task_state,
                :up_state,
                :down_state,
                :main_oc,
                :scroll_text,
                :scroll_index,
                :timers,
                :type_sym,
                :bus

  def initialize(addr="01")
    @address          = addr
    @controller_klass = 'OcModuleController'
    @text             = ''
    @led_state        = :off
    @up_state         = :off
    @down_state       = :off
    @type_sym         = :oc
  end

  def bus=comm_bus
    @bus       = comm_bus
    @in_mutex  = Mutex.new
    @in_queue  = EM::Queue.new
    @in_timer  = EM::PeriodicTimer.new(0.01) { process_in_queue }
  end

  def push_msg(msg)
    @in_mutex.synchronize do
      @in_queue.push msg
    end
  end

  def process_in_queue
    @in_mutex.synchronize do
      unless @in_queue.empty?
        @in_queue.pop do |msg|
          led_states    = msg.slice(9,1)
          control_byte  = msg.slice(10,1).hex
          text          = msg.slice(11..-3)
          text.slice!(29..-1)

          @timers       = []
          @scroll_text  = nil
          @scroll_index = 0

          if text.size > 12
            @text        = "            "
            @scroll_text = "         " + text
          else
            @text        = text
          end

          case led_states
            when "0" then
              @led_state = :off
            when "1" then
              @led_state = :fast
            when "2" then
              @led_state = :slow
            when "3" then
              @led_state = :on
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
pp "LED States: <#{led_states}>"
pp "Control Byte: <#{control_byte}>"
pp "Text: <#{text}>"
          @controller.activate_module(self)
        end
      end
    end
  end
end
