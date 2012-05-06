class BayModuleController < ApplicationController
  set_model 'BayModuleModel'
  set_view  'BayModuleView'
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
    if model.light_groupings.nil? or model.light_groupings.empty?
      model.devices.each do |device|
        c =  eval("#{device.controller_klass}.create_instance")
        @controllers << c
        device.controller = c
        add_nested_controller(device.type_sym, c)
        c.open(:model => device)
      end
    else
      model.light_groupings.each do |group|
        c =  eval("#{group.controller_klass}.create_instance")
        @controllers << c
        add_nested_controller(:light_group, c)
        c.open(:model => group)
      end
    end
  end
end