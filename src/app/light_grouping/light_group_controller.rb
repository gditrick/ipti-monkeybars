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
    model.rows.each do |row|
      c =  eval("#{row.controller_klass}.create_instance")
      @controllers << c
      add_nested_controller(:light_row, c)
      c.open(:model => row)
      @max_width = row.width > @max_width ? row.width : @max_width
    end
    model.width = @max_width
    transfer[:width]  = @max_width
  end
end