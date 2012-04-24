require 'pp'
class LightBarView < ApplicationView
  set_java_class 'app.light_bar.LightBarFrame'

  attr_accessor :current_x_pos, :current_y_pos, :current_width, :current_height

  nest :sub_view => :oc, :using => [:add_oc, :remove_oc]
  nest :sub_view => :d4, :using => [:add_d4, :remove_d4]

  def load
    @current_x_pos = 0
    @current_y_pos = 0
    @current_width = 0
    @constraints = Java::JavaAwt::GridBagConstraints.new
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
    if @current_width + nested_view.width > screen_size.width
      pp "New Line of Lights"
      @current_width =  0
      @current_x_pos =  0
      @current_y_pos += 1
    end
    @constraints.fill  = Java::JavaAwt::GridBagConstraints::HORIZONTAL
    @constraints.gridx = @current_x_pos
    @constraints.gridy = @current_y_pos
    lights_panel.add(nested_component, @constraints)
    #nested_component.set_location(@current_x_pos, @current_y_pos)
    #if lights_panel.width <= @current_x_pos + nested_view.width
    #  lights_panel.width(@current_x_pos + nested_view.width)
    #end
    @current_x_pos += 1
    @current_width += nested_view.width
    #lights_panel.validate
    #lights_panel.repaint
    #lights_pane.validate
    #lights_pane.repaint
    #pp @main_view_component.size.width = @current_x_pos
    #pp @main_view_component.preferred_size.width = @current_x_pos
    #@main_view_component.size.width = @current_x_pos
    #@main_view_component.preferred_size.width = @current_x_pos
    #pp @main_view_component.size.width = @current_x_pos
    #pp @main_view_component.preferred_size.width = @current_x_pos
    #@main_view_component.preferred_size.width = @current_x_pos
    #pp @main_view_component
    #@main_view_component.validate
    @main_view_component.pack
  end
end
