class LightBarView < ApplicationView
  set_java_class 'app.light_bar.LightBarFrame'

  nest :sub_view => :bay, :view => :bays_tab_pane

  map :model => :width,           :view => "light_scroll_pane.preferredSize.width"
  map :model => :height,          :view => "light_scroll_pane.preferredSize.height"
  map :model => :width,           :view => "bays_tab_pane.preferredSize.width"
  map :model => :height,          :view => "bays_tab_pane.preferredSize.height"

  def load
    bays_tab_pane.remove_all
  end

  def on_first_update(model, transfer)
    @main_view_component.set_size(transfer[:preferred_width], transfer[:preferred_height])
    super
  end
end
