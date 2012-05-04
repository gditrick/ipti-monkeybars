class OcModuleController < ApplicationController
  set_model 'OcModuleModel'
  set_view  'OcModuleView'

  add_listener :type => :action, :components => "led_button"
  add_listener :type => :action, :components => "up_button"
  add_listener :type => :action, :components => "down_button"

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
    unless model.scroll_text.nil?
      timer = EM::PeriodicTimer.new(0.150) do
        model.text = model.scroll_text.slice(model.scroll_index, 12)
        model.text += model.scroll_text.slice(0, 12 - model.text.size) if model.text.size < 12
        model.scroll_index += 1
        model.scroll_index = model.scroll_index % model.scroll_text.size
        update_model(model, *model.attributes)
        update_view
      end
      model.timers << timer
    end
    update_model(model, *model.attributes)
    update_view
  end

  def led_button_action_performed
    model.timers.each(&:cancel)
    model.text       = ""
    model.led_state  = :off
    model.up_state   = :off
    model.down_state = :off
    update_view
  end

  def up_button_action_performed
    update_view
  end

  def down_button_action_performed
    update_view
  end
end