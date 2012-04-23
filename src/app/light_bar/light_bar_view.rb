require 'pp'
class LightBarView < ApplicationView
  set_java_class 'app.light_bar.LightBarFrame'

  attr_accessor :current_x_pos, :current_y_pos, :current_width, :current_height

  nest :sub_view => :oc, :using => [:add_oc, :remove_oc]
  nest :sub_view => :d4, :using => [:add_d4, :remove_d4]

  def load
    @current_x_pos = 0
    @current_y_pos = 0
    lights_panel.remove_all
  end

  def add_oc(nested_view, nested_component, model, transfer)
    pp "Adding OC"
    add_device(nested_view, nested_component, model, transfer)
  end

  def remove_oc(nested_view, nested_component, model, transfer)
    lights_panel.remove nested_component
  end

  def add_d4(nested_view, nested_component, model, transfer)
    pp "Adding D4"
    add_device(nested_view, nested_component, model, transfer)
  end

  def remove_d4(nested_view, nested_component, model, transfer)
    lights_panel.remove nested_component
  end

  def add_device(nested_view, nested_component, model, transfer)
    pp nested_component
    lights_panel.add  nested_component
    nested_component.set_location(@current_x_pos, @current_y_pos)
    if lights_panel.width <= @current_x_pos + nested_view.width
      lights_panel.width(@current_x_pos + nested_view.width)
    end
    @current_x_pos += nested_view.width
    pp @current_x_pos

  end
end
