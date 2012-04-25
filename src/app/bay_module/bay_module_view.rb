require 'pp'
class BayModuleView < ApplicationView
  set_java_class 'app.bay_module.BayModulePanel'

  attr_accessor :current_x_pos, :current_y_pos, :current_width, :current_height

  map  :model => :address, :view => "bay_address.text", :using => [:address_to_tab_title, :tab_title_to_address]

  nest :sub_view => :oc,   :using => [:add_oc, :remove_oc]
  nest :sub_view => :d4,   :using => [:add_d4, :remove_d4]

  def load
    @current_x_pos = 0
    @current_y_pos = 0
    @current_width = 0
    @constraints = Java::JavaAwt::GridBagConstraints.new
    lights_panel.remove_all
  end

  def address_to_tab_title(model)
    pp @main_view_component.parent
    pp "Index = #{model}"
    pp @main_view_component.parent.title_at(model.to_i - 1)
    @main_view_component.parent.set_title_at(model.to_i - 1, "Bay #{model}")
    model
  end

  def tab_title_to_address(model)
    @main_view_component.parent.title_at(model).gsub("Bay ", "")
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
    @current_x_pos += 1
    @current_width += nested_view.width
  end
end
