require 'pp'
class BayModuleController < ApplicationController
  set_model 'BayModuleModel'
  set_view  'BayModuleView'
  set_close_action :close

  def load(*args)
    unless args.compact.empty?
      options = Hash[*args.flatten]
      if options.has_key?(:model)
        model = options[:model]
        update_model(model)
      end
    end
    @controllers ||= []
    model.devices.each do |device|
      c =  eval("#{device.controller_klass}.create_instance")
      @controllers << c
      add_nested_controller(device.type_sym, c)
      c.open(:model => device)
    end
  end
end