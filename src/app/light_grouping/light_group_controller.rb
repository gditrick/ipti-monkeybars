class LightGroupController < ApplicationController
  set_model 'LightGroupModel'
  set_view  'LightGroupView'
  set_close_action :close

  def load(*args)
    unless args.compact.empty?
      options = Hash[*args.flatten]
      if options.has_key?(:model)
        model = options[:model]
        update_model(model, *model.attributes)
      end
    end
    @controllers ||= []
    @max_width = 0
    model.height = 0
    model.rows.each do |row|
      c =  eval("#{row.controller_klass}.create_instance")
      @controllers << c
      add_nested_controller(:light_row, c)
      c.open(:model => row)
      @max_width = row.width > @max_width ? row.width : @max_width
      model.height += row.height
    end
    model.height     += 4
    model.width       = @max_width + APP_WIDTH_FUDGE
    transfer[:width]  = model.width
    transfer[:height] = model.height
  end
end