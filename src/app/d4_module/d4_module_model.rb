require 'abstract_model'

class D4ModuleModel < AbstractModel
  attr_accessor :add_state,
                :address,
                :blink,
                :bus,
                :controller_klass,
                :controller,
                :digits,
                :down_arrow_color,
                :down_arrow_state,
                :ext_functions,
                :fails,
                :fail_rate,
                :fast_blinkers,
                :fast_blink_count,
                :led_color,
                :led_colors,
                :led_state,
                :display_items,
                :display_led_states,
                :current_display_index,
                :quantity,
                :recall,
                :shorting,
                :slow_blinkers,
                :slow_blink_count,
                :state,
                :sub_state,
                :type_sym,
                :up_arrow_color,
                :up_arrow_state

  def initialize(addr="01")
    @address          = addr
    @controller_klass = 'D4ModuleController'
    @digits           = ''
    @led_state        = :off
    @fails            = false
    @fail_rate        = 0
    @add_state        = :off
    @sub_state        = :off
    @state            = :idle
    @type_sym         = :d4
  end

  def to_yaml_properties
    ["@address", "@controller_klass", "@fail_rate", "@type_sym"]
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
            when :d4_display then
              display_order(message.bytes)
              @controller.activate_module(self) if self.worked?
            when :d4_menu then
              display_menu(message.bytes)
              @controller.activate_module(self) if self.worked?
            when :cancel_order
              @controller.cancel
            else
              raise "Unknown 4 Digit Message Type #{message.message_type.type}"
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

  def display_order(msg)
    qty           = msg.slice(9,4)
    text          = msg.slice(13,4)
    led_states    = msg.slice(17,1).hex
    recall_short  = msg.slice(18,1).hex
    ext_function  = msg.slice(19,1).hex
    infrared_flag = msg.slice(20,1)
    flash_mask    = msg.slice(21,1)

    return if fail?

    @state         = :order

    @fast_blinkers = []
    @slow_blinkers = []

    @fast_blink_count = 0
    @slow_blink_count = 0

    @display_items = []
    @led_colors    = [:bright_red, :light_gray]
    @blink         = false

    @up_arrow_color   = :light_gray
    @down_arrow_color = :light_gray

    if qty == "    "
      @quantity = nil
      @display_items << text
    else
      @quantity = qty.to_i
      @digits   = qty
    end

    @up_arrow_state   = :off
    @down_arrow_state = :off

    @recall           = false
    @shorting         = :normal

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

    @blink = true unless @slow_blinkers.empty? and @fast_blinkers.empty?

    if recall_short & 1 == 1
      @recall = true
    end

    if recall_short & 2 == 2
      @shorting = :normal
    elsif recall_short & 4 == 4
      if recall_short & 8 == 8
        @shorting = :over_pick
      else
        @shorting = :pick_full_only
      end
    elsif recall_short & 8 == 8
      @shorting = :pick_full_zero
    end

    case @shorting
      when :normal then
        (0..@quantity).reverse_each{|a| @display_items << "%4d" % a}
      when :pick_full_only
        @display_items << "%4d" % @quantity
      when :pick_full_zero
        @display_items << "%4d" % @quantity
        @display_items << "%4d" % 0
      when :over_pick
        (0..@quantity).reverse_each{|a| @display_items << "%-4.4d" % a}
    end unless @quantity.nil?

    if @recall
      @display_items << "rCAL"
    end unless @quantity.nil?

    @ext_functions = []
    if ext_function & 1 == 1
      @ext_functions << :close_box
      @display_items << "cLOS"
    end unless @quantity.nil?
    if ext_function & 2 == 2
      @ext_functions << :stock_low
      @display_items << "LO  "
    end unless @quantity.nil?
    if ext_function & 4 == 4
      @ext_functions << :info_request
      @display_items << "InFO"
    end unless @quantity.nil?
    if ext_function & 8 == 8
      @ext_functions << :scrap
      @display_items << "SCrP"
    end unless @quantity.nil?

    if @shorting == :over_pick
      (9999...@quantity).each{|a| @display_items << "%-4.4d" % a}
    end unless @quantity.nil?

    @led_state        = :on
    @led_color        = :bright_red

    unless @quantity.nil?
      @add_state        = :on
      @sub_state        = :on
    end

    @current_display_index = 0
    @digits                = @display_items[@current_display_index]

    @up_arrow_color   = :bright_red unless @up_arrow_state == :off
    @down_arrow_color = :bright_green unless @down_arrow_state == :off
  end

  def display_menu(msg)
pp "Display Menu"
pp msg
    @state         = :menu

    @display_items = []
    @display_led_states = []
    @led_colors    = [:bright_red, :light_gray]

    @fast_blinkers = []
    @slow_blinkers = []

    @fast_blink_count = 0
    @slow_blink_count = 0

    msg.slice(9..-3).scan(/.{5}/).each do |menu_item|
pp menu_item
      @display_items << menu_item.slice(0,4)
      @display_led_states << menu_item.slice(-1,1)
    end

    return false if @display_items.empty?

pp "Menu Items:"
pp @display_items
pp "Led States:"
pp @display_led_states

    @led_state        = :on
    @led_color        = :bright_red
    @add_state        = :on
    @sub_state        = :on
    @up_arrow_color   = :light_gray
    @down_arrow_color = :light_gray

    @current_display_index = 0
    @digits                = @display_items[@current_display_index]

    @up_arrow_state   = :off
    @down_arrow_state = :off

    led_states = @display_led_states[@current_display_index].hex

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

    @blink = true unless @slow_blinkers.empty? and @fast_blinkers.empty?

    @up_arrow_color   = :bright_red unless @up_arrow_state == :off
    @down_arrow_color = :bright_green unless @down_arrow_state == :off
    true
  end
end
