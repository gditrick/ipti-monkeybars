require 'pp'
class BayModuleView < ApplicationView
  set_java_class 'app.bay_module.BayModulePanel'

  attr_accessor :current_x_pos, :current_y_pos, :current_width, :current_height
  attr_reader   :max_width, :max_height

  map  :model => :address, :view => "bay_address.text", :using => [:address_to_tab_title, :tab_title_to_address]

  nest :sub_view => :light_group, :using => [:add_light_group, :remove_light_group]
  nest :sub_view => :oc,        :using => [:add_oc, :remove_oc]
  nest :sub_view => :d4,        :using => [:add_d4, :remove_d4]

  def load
    @current_x_pos  = 0
    @current_y_pos  = 0
    @current_width  = 0
    @current_height = 0
    @max_width      = 0
    @max_height     = 0
    @constraint        = Java::JavaAwt::GridBagConstraints.new
    @constraint.anchor = Java::JavaAwt::GridBagConstraints::CENTER
    lights_panel.remove_all
  end

  def on_first_update(model, transfer)
    transfer[:preferred_width] = @max_width
    transfer[:preferred_height] = @max_height
    @main_view_component.update_ui
    super
  end

  def address_to_tab_title(attr)
    @main_view_component.parent.set_title_at(attr.to_i - 1, "Bay #{attr}")
    @main_view_component.parent.set_selected_index(@main_view_component.parent.tab_count - 1)
  end

  def tab_title_to_address(attr)
    @main_view_component.parent.title_at(attr.to_i - 1).gsub("Bay ", "")
  end

  def add_light_group(nested_view, nested_component, model, transfer)
pp transfer
    @constraint.anchor = Java::JavaAwt::GridBagConstraints::LINE_START
    @constraint.gridx  = @current_x_pos
    lights_panel.add(nested_component, @constraint)
    @current_x_pos += 1
  end

  def remove_light_group(nested_view, nested_component, model, transfer)
    lights_panel.remove nested_component
  end

  def add_oc(nested_view, nested_component, model, transfer)
    @constraint.gridwidth = 2
    add_device(nested_view, nested_component, model, transfer)
  end

  def remove_oc(nested_view, nested_component, model, transfer)
    lights_panel.remove nested_component
  end

  def add_d4(nested_view, nested_component, model, transfer)
    @constraint.gridwidth = 1
    add_device(nested_view, nested_component, model, transfer)
  end

  def remove_d4(nested_view, nested_component, model, transfer)
    lights_panel.remove nested_component
  end

  def add_device(nested_view, nested_component, model, transfer)
    @current_height = nested_view.height if @current_height == 0 or nested_view.height > @current_height
    if @current_width + nested_view.width > screen_size.width - 40
      @max_height += @current_height if @max_height + @current_height < screen_size.height - 40
      @current_width =  0
      @current_x_pos =  0
      @current_y_pos += 1
      @current_height = nested_view.height
    end
    @constraint.gridx = @current_x_pos
    @constraint.gridy = @current_y_pos
    lights_panel.add(nested_component, @constraint)
    @current_x_pos += @constraint.gridwidth
    @current_width += nested_view.width
    @max_width = @current_width if @current_width >= @max_width
  end
end
