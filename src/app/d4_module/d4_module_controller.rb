class D4ModuleController < ApplicationController
  set_model 'D4ModuleModel'
  set_view 'D4ModuleView'

  attr_accessor :timers, :timer_mutex

  DOWN_ARROW_COLORS = [:bright_green, :gray]
  UP_ARROW_COLORS   = [:bright_red, :gray]

  def load(*args)
    @timer_mutex = Mutex.new if @timer_mutex.nil?
    @timers = []
    unless args.compact.empty?
      options = Hash[*args.flatten]
      if options.has_key?(:model)
        model = options[:model]
        update_model(model, *model.attributes)
      end
    end
  end

  def activate_module(model)
    @timer_mutex.synchronize do
      if model.blink?
        timer = EM::PeriodicTimer.new(0.200) do
          model.fast_blink_count = blink(model, model.fast_blink_count, model.fast_blinkers)
          update_model(model, :led_color, :up_arrow_color, :down_arrow_color)
          update_view
        end unless model.fast_blinkers.empty?
        @timers << timer unless model.fast_blinkers.empty?
        timer = EM::PeriodicTimer.new(0.500) do
          model.slow_blink_count = blink(model, model.slow_blink_count, model.slow_blinkers)
          update_model(model, :led_color, :up_arrow_color, :down_arrow_color)
          update_view
        end unless model.slow_blinkers.empty?
        @timers << timer unless model.slow_blinkers.empty?
      end
    end
    update_model(model, *model.attributes)
    update_view
  end

  def cancel
    deactivate_module
    update_view
  end

  def led_button_action_performed
    bus_msg = IPTI::Client::BusMessage.new
    bus_msg.code = :d4_display
    fields = {}
    fields[:d4_address] = model.address
    case model.display_items[model.current_display_index]
      when "rCAL" then
        fields[:quantity] = -1
        fields[:infrared] = "000"
        fields[:led_states] = light_states
      when "cLOS" then
      when "LO  " then
      when "InFO" then
      when "SCrP" then
      else
        fields[:quantity]   = model.display_items[model.current_display_index].to_i
        fields[:infrared]   = "000"
        fields[:led_states] = light_states
    end
    bus_msg.fields = fields
    model.bus.push_bus_msg(bus_msg)
    deactivate_module
    update_view
  end

  def add_button_action_performed
    model.current_display_index -= 1
    model.current_display_index = model.current_display_index % model.display_items.size
    model.digits     = model.display_items[model.current_display_index]
    update_view
  end

  def minus_button_action_performed
    model.current_display_index += 1
    model.current_display_index = model.current_display_index % model.display_items.size
    model.digits     = model.display_items[model.current_display_index]
    update_view
  end

  private

  def blink(model, blink_count, blinkers)
    blinkers.each do |b|
      case b
        when :up then
          model.up_arrow_color = UP_ARROW_COLORS[blink_count]
        when :down then
          model.down_arrow_color = DOWN_ARROW_COLORS[blink_count]
        when :led then
          model.led_color = model.led_colors[blink_count]
      end
    end
    blink_count += 1
    blink_count % 2
  end

  def deactivate_module
    @timer_mutex.synchronize do
      @timers.each(&:cancel) unless @timers.nil?
      @timers = []
    end
    model.digits           = ""
    model.led_state        = :off
    model.led_color        = :light_gray
    model.up_arrow_color   = :gray
    model.down_arrow_color = :gray
    model.add_state        = :off
    model.sub_state        = :off
    model.blink            = false
    model.fast_blinkers    = []
    model.slow_blinkers    = []
    model.fast_blink_count = 0
    model.slow_blink_count = 0
  end

  def light_states
    led_states = 0
    case model.up_arrow_state
      when :fast then led_states |= 1
      when :slow then led_states |= 2
      when :on then led_states |= 3
    end
    case model.down_arrow_state
      when :fast then led_states |= 4
      when :slow then led_states |= 8
      when :on then led_states |= 12
    end
    led_states
  end
end
