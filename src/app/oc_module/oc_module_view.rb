class OcModuleView < ApplicationView
  set_java_class 'app.oc_module.OcModulePanel'

  BUTTON_STATES = {:off => false, :on => true}
  map :model => :text,       :view => "displayText.text"
  map :model => :task_state, :view => "ledButton.enabled",  :translate_using => BUTTON_STATES
  map :model => :up_state,   :view => "upButton.enabled",   :translate_using => BUTTON_STATES
  map :model => :down_state, :view => "downButton.enabled", :translate_using => BUTTON_STATES
end
