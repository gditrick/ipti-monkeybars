require 'pp'
class LightBarView < ApplicationView
  set_java_class 'app.light_bar.LightBarFrame'

  attr_accessor :current_x_pos, :current_y_pos, :current_width, :current_height

  nest :sub_view => :oc, :using => [:add_oc, nil]

  def load
    lights_panel.remove_all
  end

  def add_oc(nested_view, nested_component, model, transfer)
    lights_panel.add  nested_component
    nested_component.set_location(0, 0)
  end
end
