class D4ModuleView < ApplicationView
  set_java_class 'app.d4_module.D4ModulePanel'

  BUTTON_STATES = {:off => false, :on => true}
  map :model => :digits,     :view => "digitsField.text"
  map :model => :led_state,  :view => "ledButton.enabled",       :translate_using => BUTTON_STATES
  map :model => :add_state,  :view => "addButton.enabled",       :translate_using => BUTTON_STATES
  map :model => :sub_state,  :view => "minusButton.enabled",     :translate_using => BUTTON_STATES
end
