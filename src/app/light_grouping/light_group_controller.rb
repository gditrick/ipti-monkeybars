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
    model.rows.each do |row|
      c =  eval("#{row.controller_klass}.create_instance")
      @controllers << c
      add_nested_controller(:light_row.type_sym, c)
      c.open(:model => row)
    end
  end
end