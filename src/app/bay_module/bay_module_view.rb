require 'pp'
class BayModuleView < ApplicationView
  set_java_class 'app.bay_module.BayModulePanel'

  attr_accessor :current_x_pos, :current_y_pos, :current_width, :current_height

  map  :model => :address, :view => "bay_address.text", :using => [:address_to_tab_title, :tab_title_to_address]

  nest :sub_view => :oc,   :using => [:add_oc, :remove_oc]
  nest :sub_view => :d4,   :using => [:add_d4, :remove_d4]

  def load(*args)
    @current_x_pos = 0
    @current_y_pos = 0
    @current_width = 0
    @max_width = 0
    @constraints = []
    @constraints << Java::JavaAwt::GridBagConstraints.new
    lights_panel.remove_all
  end

  def address_to_tab_title(attr)
    @main_view_component.parent.set_title_at(attr.to_i - 1, "Bay #{attr}")
    attr
  end

  def tab_title_to_address(attr)
    @main_view_component.parent.title_at(attr.to_i - 1).gsub("Bay ", "")
  end

  def add_oc(nested_view, nested_component, model, transfer)
    add_device(nested_view, nested_component, model, transfer)
  end

  def remove_oc(nested_view, nested_component, model, transfer)
    lights_panel.remove nested_component
  end

  def add_d4(nested_view, nested_component, model, transfer)
    add_device(nested_view, nested_component, model, transfer)
  end

  def remove_d4(nested_view, nested_component, model, transfer)
    lights_panel.remove nested_component
  end

  def add_device(nested_view, nested_component, model, transfer)
    if @current_width + nested_view.width > screen_size.width
      @current_width =  0
      @current_x_pos =  0
      @current_y_pos += 1
      @constraints << Java::JavaAwt::GridBagConstraints.new
      @constraints.last.fill  = Java::JavaAwt::GridBagConstraints::HORIZONTAL
    end
    @constraints.last.gridx = @current_x_pos
    @constraints.last.gridy = @current_y_pos
    lights_panel.add(nested_component, @constraints.last)
    @current_x_pos += 1
    @current_width += nested_view.width
    @max_width = @current_width if @current_width >= @max_width
  end
end
