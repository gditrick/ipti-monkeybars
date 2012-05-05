require 'abstract_model'

class D4ModuleModel < AbstractModel
  attr_accessor :add_state,
                :address,
                :blink_leds,
                :bus,
                :controller_klass,
                :controller,
                :digits,
                :down_arrow_color,
                :down_arrow_state,
                :ext_functions,
                :fast_blinkers,
                :fast_blink_count,
                :led_color,
                :led_colors,
                :led_state,
                :display_items,
                :current_display_index,
                :quantity,
                :recall_short,
                :slow_blinkers,
                :slow_blink_count,
                :sub_state,
                :timers,
                :type_sym,
                :up_arrow_color,
                :up_arrow_state

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
          led_states    = msg.slice(17,1).hex
          recall_short  = msg.slice(18,1)
          ext_function  = msg.slice(19,1).hex
          infrared_flag = msg.slice(20,1)
          flash_mask    = msg.slice(21,1)

          @fast_blink_count = 0
          @slow_blink_count = 0

          @timers        = []
          @display_items = []
          @fast_blinkers = []
          @slow_blinkers = []
          @led_colors    = [:bright_red, :light_gray]
          @blink_leds    = false

          @quantity = qty.to_i
          @digits   = qty

          @up_arrow_state   = :off
          @down_arrow_state = :off

          if led_states & 1 == 1
            @up_arrow_state = :fast
            if led_states & 2 == 2
              @up_arrow_state = :on
            else
              @fast_blinkers << :up
            end
          elsif led_states & 2 == 2
            @up_arrow_state = :slow
            @slow_blinkers << :up
          end

          if led_states & 4 == 4
            @down_arrow_state = :fast
            if led_states & 8 == 8
              @down_arrow_state = :on
            else
              @fast_blinkers << :down
            end
          elsif led_states & 8 == 8
            @down_arrow_state = :slow
            @slow_blinkers << :down
          end

          @slow_blinkers << :led unless @slow_blinkers.empty? or @fast_blinkers.size > 0
          @fast_blinkers << :led if @slow_blinkers.empty? and @fast_blinkers.size > 0

          @blink_leds = true unless @slow_blinkers.empty? and @fast_blinkers.empty?

          case recall_short
            when "0" then
              @recall_short = :normal
              (0..@quantity).reverse_each{|a| @display_items << "%4d" % a}
            when "1" then
              @recall_short = :pick_full_only
              @display_items << "%4d" % @quantity
            when "2" then
              @recall_short = :pick_full_zero
              @display_items << "%4d" % @quantity
              @display_items << "%4d" % 0
            when "3" then
              @recall_short = :over_pick
              (0..@quantity).reverse_each{|a| @display_items << "%-4.4d" % a}
          end

          @ext_functions = []
          if ext_function & 1 == 1
            @ext_functions << :close_box
            @display_items << "cLOS"
          end
          if ext_function & 2 == 2
            @ext_functions << :stock_low
            @display_items << "LO  "
          end
          if ext_function & 4 == 4
            @ext_functions << :info_request
            @display_items << "InFO"
          end
          if ext_function & 8 == 8
            @ext_functions << :scrap
            @display_items << "SCrP"
          end

          if @recall_short == :over_pick
            (9999...@quantity).each{|a| @display_items << "%-4.4d" % a}
          end


          @led_state        = :on
          @led_color        = :bright_red
          @add_state        = :on
          @sub_state        = :on

          @blink_leds      = true if @up_arrow_state == :slow or
                                     @up_arrow_state == :fast or
                                     @down_arrow_state == :fast or
                                     @down_arrow_state == :slow

          @up_arrow_color   = :bright_red unless @up_arrow_state == :off
          @down_arrow_color = :bright_green unless @down_arrow_state == :off

          @current_display_index = 0
          @digits                = @display_items[@current_display_index]

          @controller.activate_module(self)
        end
      end
    end
  end

  def blink_leds?
    @blink_leds
  end
end
