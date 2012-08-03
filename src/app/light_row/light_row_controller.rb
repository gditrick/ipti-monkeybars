class LightRowController < ApplicationController
  set_model 'LightRowModel'
  set_view  'LightRowView'
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
    model.devices.each do |device|
      c =  eval("#{device.controller_klass}.create_instance")
      @controllers << c
      device.controller = c
      add_nested_controller(device.type_sym, c)
      c.open(:model => device)
    end
    model.width = transfer[:width]
    model.height = transfer[:height]
  end
end