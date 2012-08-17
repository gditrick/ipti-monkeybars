class LightBarView < ApplicationView
  set_java_class 'app.light_bar.LightBarFrame'

  nest :sub_view => :bay,                   :view => :bays_tab_pane
  nest :sub_view => :interface_configure,   :using => [:add_config, nil]

  map :model => :status_message,                       :view => "message_label.text"
  map :model => :last_sent_message,                    :view => "last_sent_field.text"
  map :model => :last_recv_message,                    :view => "last_recv_field.text"
  map :model => "app.disconnected?",                   :view => "connect_menu_item.enabled"
  map :model => "app.connected?",                      :view => "disconnect_menu_item.enabled"
  map :model => "app.does_configuration_need_saving?", :view => "save_menu_item.enabled"

  def load
    bays_tab_pane.remove_all
  end

  def on_first_update(model, transfer)
    @main_view_component.set_size(transfer[:preferred_width], transfer[:preferred_height])
    super
  end

  def add_config(nested_view, nested_component, model, transfer)
    nested_component.location_relative_to = @main_view_component
  end
end
