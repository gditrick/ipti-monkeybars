require 'oc_module_controller'
require 'pp'

class LightBarController < ApplicationController
  attr_accessor  :initial_model

  set_model 'LightBarModel'
  set_view 'LightBarView'
  set_close_action :exit

  def load(*args)
    unless args.compact.empty?
      options = Hash[*args.flatten]
      if options.has_key?(:model)
        model = options[:model]
        update_model(model)
      end
    end
    pp model
    @controllers ||= []
    model.devices.each do |device|
      pp device
      pp device.address
      pp device.controller_klass
      c =  eval("#{device.controller_klass}.instance")
      pp c
      @controllers << c
      pp device.type_sym
      add_nested_controller(device.type_sym, c)
    end
    @controllers.first.open
  end
end