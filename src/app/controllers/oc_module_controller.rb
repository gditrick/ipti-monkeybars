class OcModuleController < ApplicationController
  set_model 'OcModule'
  set_view  'OcModuleView'

  def led_button_action_performed
    model.text      = ""
    model.ledState  = :off
    model.upState   = :off
    model.downState = :off
    update_view
  end
end