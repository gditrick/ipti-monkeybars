class D4ModuleView < ApplicationView
  set_java_class 'app.d4_module.D4ModulePanel'

  BUTTON_STATES = {:off => false, :on => true}

  LED_COLORS = {
      :bright_red   => Java::JavaAwt::Color::RED.brighter,
      :bright_green => Java::JavaAwt::Color::GREEN.brighter,
      :dark_gray    => Java::JavaAwt::Color::DARK_GRAY,
      :gray         => Java::JavaAwt::Color::GRAY,
      :light_gray   => Java::JavaAwt::Color::LIGHT_GRAY
  }

  map :model => :digits,           :view => "digitsField.text"
  map :model => :led_state,        :view => "ledButton.enabled",           :translate_using => BUTTON_STATES
  map :model => :led_color,        :view => "ledButton.background",        :translate_using => LED_COLORS
  map :model => :up_arrow_color,   :view => "upArrowButton.background",    :translate_using => LED_COLORS
  map :model => :down_arrow_color, :view => "downArrowButton.background",  :translate_using => LED_COLORS
  map :model => :add_state,        :view => "addButton.enabled",           :translate_using => BUTTON_STATES
  map :model => :sub_state,        :view => "minusButton.enabled",         :translate_using => BUTTON_STATES
end
