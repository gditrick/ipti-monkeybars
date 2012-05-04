class D4ModuleController < ApplicationController
  set_model 'D4ModuleModel'
  set_view 'D4ModuleView'

  DOWN_ARROW_COLORS = [:bright_green, :gray]
  UP_ARROW_COLORS   = [:bright_red, :gray]

  def load(*args)
    unless args.compact.empty?
      options = Hash[*args.flatten]
      if options.has_key?(:model)
        model = options[:model]
        update_model(model, *model.attributes)
      end
    end
  end

  def activate_module(model)
    if model.blink_leds?
      timer = EM::PeriodicTimer.new(0.200) do
        model.fast_blink_count = blink(model, model.fast_blink_count, model.fast_blinkers)
        update_model(model, *model.attributes)
        update_view
      end unless model.fast_blinkers.empty?
      timer = EM::PeriodicTimer.new(0.500) do
        model.slow_blink_count = blink(model, model.slow_blink_count, model.slow_blinkers)
        update_model(model, *model.attributes)
        update_view
      end unless model.slow_blinkers.empty?
      model.timers << timer
    end
    update_model(model, *model.attributes)
    update_view
  end

  def led_button_action_performed
    model.timers.each(&:cancel)
    model.digits           = ""
    model.led_state        = :off
    model.led_color        = :light_gray
    model.up_arrow_color   = :gray
    model.down_arrow_color = :gray
    model.add_state        = :off
    model.sub_state        = :off
    update_view
  end

  def add_button_action_performed
    model.current_display_index += 1
    model.current_display_index = model.current_display_index % model.display_items.size
    model.digits     = model.display_items[model.current_display_index]
    update_view
  end

  def minus_button_action_performed
    model.current_display_index -= 1
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
end
