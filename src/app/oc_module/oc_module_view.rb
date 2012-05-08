class OcModuleView < ApplicationView
  set_java_class 'app.oc_module.OcModulePanel'

  BUTTON_STATES = {:off => false, :on => true}

  LED_COLORS = {
      :bright_cyan      => Java::JavaAwt::Color::CYAN.brighter,
      :deep_sky_blue    => Java::JavaAwt::Color.new(0x00BFFF),
      :deep_turquoise   => Java::JavaAwt::Color.new(0x00CED1),
      :medium_turquoise => Java::JavaAwt::Color.new(0x48D1CC),
      :light_gray       => Java::JavaAwt::Color::LIGHT_GRAY
  }

  map :model => :text,       :view => "displayText.text"
  map :model => :task_state, :view => "ledButton.enabled",     :translate_using => BUTTON_STATES
  map :model => :led_color,  :view => "ledButton.background",  :translate_using => LED_COLORS
  map :model => :up_state,   :view => "upButton.enabled",      :translate_using => BUTTON_STATES
  map :model => :down_state, :view => "downButton.enabled",    :translate_using => BUTTON_STATES
end
