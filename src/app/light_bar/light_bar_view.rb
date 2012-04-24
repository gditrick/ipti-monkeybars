require 'pp'
class LightBarView < ApplicationView
  set_java_class 'app.light_bar.LightBarFrame'

  nest :sub_view => :bay, :view => :bays_tab_pane

  def load
    bays_tab_pane.remove_all
  end

#  def add_bay(nested_view, nested_component, model, transfer)
#    pp "Adding Bay"
#    pp nested_view
#    pp nested_component
#    pp model
#    pp transfer
#    model.bays.each do |bay|
#      bays_tab_pane.add("Bay #{bay.address}", nested_component)
#    end
#    @main_view_component.pack
#  end
#
#  def remove_bay(nested_view, nested_component, model, transfer)
#    bays_tab_pane.removeall
#  end
end
