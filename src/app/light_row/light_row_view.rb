class LightRowView < ApplicationView
  set_java_class 'app.light_rgrouping.LightGroupPanel'

  attr_accessor :current_x_pos, :current_y_pos, :current_width, :current_height

  nest :sub_view => :light_row,   :using => [:add_row, :remove_row]

  def load
    @current_x_pos = 0
    @current_y_pos = 0
    @current_width = 0
    @max_width = 0
    @constraints = []
    @constraints << Java::JavaAwt::GridBagConstraints.new
    #@constraints.last.fill  = Java::JavaAwt::GridBagConstraints::HORIZONTAL
    @constraints.last.anchor = Java::JavaAwt::GridBagConstraints::LINE_START
    lights_panel.remove_all
  end

  def add_row(nested_view, nested_component, model, transfer)
    if @current_width + nested_view.width > screen_size.width
      @current_width =  0
      @current_x_pos =  0
      @current_y_pos += 1
      @constraints << Java::JavaAwt::GridBagConstraints.new
      #@constraints.last.fill  = Java::JavaAwt::GridBagConstraints::HORIZONTAL
      @constraints.last.anchor = Java::JavaAwt::GridBagConstraints::LINE_START
    end
    @constraints.last.gridx = @current_x_pos
    @constraints.last.gridy = @current_y_pos
    lights_panel.add(nested_component, @constraints.last)
    @current_x_pos += 1
    @current_width += nested_view.width
    @max_width = @current_width if @current_width >= @max_width
    add_device(nested_view, nested_component, model, transfer)
  end

  def remove_row(nested_view, nested_component, model, transfer)
    light_group_panel.remove nested_component
  end
end
