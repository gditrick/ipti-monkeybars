require 'eventmachine'

class OcModuleModel < AbstractModel
  attr_accessor :address,
                :controller_klass,
                :controller,
                :text,
                :led_state,
                :up_state,
                :down_state,
                :main_oc,
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
          control_byte  = msg.slice(10,1)
          text          = msg.slice(11..-3)
          self.text     = text
pp "LED States: <#{led_states}>"
pp "Control Byte: <#{control_byte}>"
pp "Text: <#{text}>"
          @controller.update_view
          @controller.update_view
        end
      end
    end
  end
end
