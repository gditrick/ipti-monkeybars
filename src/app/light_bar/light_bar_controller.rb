require 'pp'
class LightBarController < ApplicationController
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
    @controllers ||= []
    model.bays.each do |bay|
      c =  eval("#{bay.controller_klass}.create_instance")
      @controllers << c
      add_nested_controller(bay.type_sym, c)
      c.open(:model => bay)
    end
  end
end