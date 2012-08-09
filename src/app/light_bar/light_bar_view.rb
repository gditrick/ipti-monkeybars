class LightBarView < ApplicationView
  set_java_class 'app.light_bar.LightBarFrame'

  nest :sub_view => :bay, :view => :bays_tab_pane

  def load
    bays_tab_pane.remove_all
  end

  def on_first_update(model, transfer)
    pp transfer[:bays_tab_pane_width]
    pp transfer[:bays_tab_pane_height]
#    bays_tab_pane.set_size(transfer[:bays_tab_pane_width], transfer[:bays_tab_pane_height])
#    light_scroll_pane.set_size(transfer[:bays_tab_pane_width], transfer[:bays_tab_pane_height])
#    bays_tab_pane.set_preferred_size(Java::JavaAwt::Dimension.new(transfer[:bays_tab_pane_width], transfer[:bays_tab_pane_height]))
#    light_scroll_pane.set_preferred_size(Java::JavaAwt::Dimension.new(transfer[:bays_tab_pane_width], transfer[:bays_tab_pane_height]))
    @main_view_component.set_size(transfer[:preferred_width], transfer[:preferred_height])
    super
  end
end
