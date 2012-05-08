class OcModuleController < ApplicationController
  set_model 'OcModuleModel'
  set_view  'OcModuleView'

  attr_accessor :timers, :timer_mutex

  add_listener :type => :action, :components => "led_button"
  add_listener :type => :action, :components => "up_button"
  add_listener :type => :action, :components => "down_button"

  LED_COLORS = [:bright_cyan, :light_gray]

  def load(*args)
    @timer_mutex = Mutex.new if @timer_mutex.nil?
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
      @timers.each(&:cancel) unless @timers.nil?
      @timers       = []
      unless model.scroll_text.nil?
        timer = EM::PeriodicTimer.new(0.150) do
          unless model.scroll_text.nil?
            model.text = model.scroll_text.slice(model.scroll_index, 12)
            model.text += model.scroll_text.slice(0, 12 - model.text.size) if model.text.size < 12
            model.scroll_index += 1
            model.scroll_index = model.scroll_index % model.scroll_text.size
            update_model(model, *model.attributes)
            update_view
          end
        end
        @timers << timer
      end
      if model.blink?
        timer = EM::PeriodicTimer.new(0.200) do
          model.fast_blink_count = blink(model, model.fast_blink_count, model.fast_blinkers)
          update_model(model, *model.attributes)
          update_view
        end unless model.fast_blinkers.empty?
        @timers << timer unless model.fast_blinkers.empty?
        timer = EM::PeriodicTimer.new(0.500) do
          model.slow_blink_count = blink(model, model.slow_blink_count, model.slow_blinkers)
          update_model(model, *model.attributes)
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
    bus_msg = create_oc_display_message
    bus_msg.fields.merge!({:button_pressed => "1"})
    model.bus.push_bus_msg(bus_msg)
    deactivate_module
    update_view
  end

  def up_button_action_performed
    bus_msg = create_oc_display_message
    bus_msg.fields.merge!({:button_pressed => "2"})
    model.bus.push_bus_msg(bus_msg)
    deactivate_module
    update_view
  end

  def down_button_action_performed
    bus_msg = create_oc_display_message
    bus_msg.fields.merge!({:button_pressed => "3"})
    model.bus.push_bus_msg(bus_msg)
    deactivate_module
    update_view
  end

  private

  private

  def blink(model, blink_count, blinkers)
    blinkers.each do |b|
      case b
        when :led then
          model.up_arrow_color = LED_COLORS[blink_count]
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
    model.text         = ""
    model.led_state    = :off
    model.task_state   = :off
    model.led_color    = :light_gray
    model.up_state     = :off
    model.down_state   = :off
    model.scroll_text  = nil
    model.scroll_index = 0
    model.blink        = false
    model.fast_blinkers    = []
    model.slow_blinkers    = []
    model.fast_blink_count = 0
    model.slow_blink_count = 0
  end

  def create_oc_display_message
    bus_msg = IPTI::Client::BusMessage.new(:oc_display)
    bus_msg.fields[:oc_address] = model.address.to_i
    bus_msg
  end
end