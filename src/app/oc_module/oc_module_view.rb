class OcModuleView < ApplicationView
  set_java_class 'app.oc_module.OcModulePanel'

  BUTTON_STATES = {:off => false, :on => true}
  map :model => :text,      :view => "displayText.text"
  map :model => :ledState,  :view => "ledButton.enabled",  :translate_using => BUTTON_STATES
  map :model => :upState,   :view => "upButton.enabled",   :translate_using => BUTTON_STATES
  map :model => :downState, :view => "downButton.enabled", :translate_using => BUTTON_STATES
end
