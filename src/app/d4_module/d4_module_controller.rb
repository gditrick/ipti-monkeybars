class D4ModuleController < ApplicationController
  set_model 'D4ModuleModel'
  set_view 'D4ModuleView'

  def led_button_action_performed
    model.digits    = ""
    model.ledState  = :off
    model.addState  = :off
    model.subSate   = :off
    update_view
  end
end
