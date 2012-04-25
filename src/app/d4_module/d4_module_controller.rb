class D4ModuleController < ApplicationController
  set_model 'D4ModuleModel'
  set_view 'D4ModuleView'

  def load(*args)
    unless args.compact.empty?
      options = Hash[*args.flatten]
      if options.has_key?(:model)
        model = options[:model]
        update_model(model, *model.attributes)
      end
    end
  end

  def led_button_action_performed
    model.digits    = ""
    model.ledState  = :on
    model.addState  = :off
    model.subState  = :off
    update_view
  end
end
