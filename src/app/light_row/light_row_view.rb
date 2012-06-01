class LightRowView < ApplicationView
  set_java_class 'app.light_row.LightRowPanel'

  attr_accessor :current_x_pos, :current_y_pos, :current_width, :current_height

  nest :sub_view => :oc,          :using => [:add_oc, :remove_oc]
  nest :sub_view => :d4,          :using => [:add_d4, :remove_d4]

  def load
    @current_x_pos     = 0
    @width             = 0
    @constraint        = Java::JavaAwt::GridBagConstraints.new
    @constraint.gridy  = 0
    @constraint.anchor = Java::JavaAwt::GridBagConstraints::LINE_START
    light_row_panel.remove_all
  end

  def on_first_update(model, transfer)
    transfer[:width] = @width
    @main_view_component.set_size(transfer[:width], 80)
    super
  end

  def add_oc(nested_view, nested_component, model, transfer)
    add_device(nested_view, nested_component, model, transfer)
  end

  def remove_oc(nested_view, nested_component, model, transfer)
    light_row_panel.remove nested_component
  end

  def add_d4(nested_view, nested_component, model, transfer)
    add_device(nested_view, nested_component, model, transfer)
  end

  def remove_d4(nested_view, nested_component, model, transfer)
    light_row_panel.remove nested_component
  end

  def add_device(nested_view, nested_component, model, transfer)
    @constraint.gridx = @current_x_pos
    light_row_panel.add(nested_component, @constraint)
    @current_x_pos += 1
    @width += nested_view.width
    transfer[:width] = @width
  end
end
