require 'pp'
class LightBarView < ApplicationView
  set_java_class 'app.light_bar.LightBarFrame'

  nest :sub_view => :bay, :using => [:add_bay, :remove_bay]

  def load
    bays_tab_pane.remove_all
  end

  def add_bay(nested_view, nested_component, model, transfer)
    pp "Adding Bay"
    pp nested_view
    pp nested_component
    pp model
    pp transfer
    bays_tab_pane.add("Bay", nested_component)
  end

  def remove_bay(nested_view, nested_component, model, transfer)
    bays_tab_pane.removeall
  end
end
