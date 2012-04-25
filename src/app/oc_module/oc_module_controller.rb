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
        update_model(model)
      end
    end
  end

  def led_button_action_performed
    model.text      = ""
    model.ledState  = :off
    model.upState   = :off
    model.downState = :off
    update_view
  end

  def up_button_action_performed
    update_view
  end

  def down_button_action_performed
    update_view
  end
end