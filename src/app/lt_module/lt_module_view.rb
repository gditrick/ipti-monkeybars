class LtModuleView < ApplicationView
  set_java_class 'app.lt_module.LtModulePanel'

  map :model => :text,       :view => "displayText.text"
end
