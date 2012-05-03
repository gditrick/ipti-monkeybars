require 'abstract_model'
class D4ModuleModel < AbstractModel
  attr_accessor :address,
                :controller_klass,
                :controller,
                :digits,
                :led_state,
                :add_state,
                :sub_state,
                :type_sym,
                :bus

  def initialize(addr="01")
    @address          = addr
    @controller_klass = 'D4ModuleController'
    @digits           = ''
    @led_state        = :off
    @add_state        = :off
    @sub_state        = :off
    @type_sym         = :d4
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
          qty           = msg.slice(9,4)
          text          = msg.slice(13,4)
          led_states    = msg.slice(17,1)
          recall_short  = msg.slice(18,1)
          ext_function  = msg.slice(19,1)
          infrared_flag = msg.slice(20,1)
          flash_mask    = msg.slice(21,1)
pp "Qty: <#{qty}>"
pp "Text: <#{text}>"
pp "LED States: <#{led_states}>"
pp "Recall/Short: <#{recall_short}>"
pp "Ext Func: <#{ext_function}>"
pp "Infrared: <#{infrared_flag}>"
pp "Flash: <#{flash_mask}>"
        end
      end
    end
  end
end
