require 'pp'
class LightGroupView < ApplicationView
  set_java_class 'app.light_grouping.LightGroupPanel'

  attr_accessor :current_x_pos, :current_y_pos, :current_width, :current_height

  nest :sub_view => :light_row,   :using => [:add_row, :remove_row]

  def load
    @constraint       = Java::JavaAwt::GridBagConstraints.new
    @current_y_pos    = 0
    @constraint.gridx = 0
    #@constraints.last.fill  = Java::JavaAwt::GridBagConstraints::HORIZONTAL
    @constraint.anchor = Java::JavaAwt::GridBagConstraints::LINE_START
    light_group_panel.remove_all
  end

  def on_first_update(model, transfer)
    @main_view_component.set_size(transfer[:width], 160)
    super
  end

  def add_row(nested_view, nested_component, model, transfer)
    @constraint.gridy = @current_y_pos
    light_group_panel.add(nested_component, @constraint)
    @current_y_pos += 1
  end

  def remove_row(nested_view, nested_component, model, transfer)
    light_group_panel.remove nested_component
  end
end
