require "oc_module_controller"

class LightBarController < ApplicationController
  attr_accessor  :initial_model

  set_model 'LightBarModel'
  set_view 'LightBarView'
  set_close_action :exit

  def load(*args)
    unless args.compact.empty?
      options = Hash[*args.flatten]
      if options.has_key?(:model)
        
        update_model(options[:model], :number_of_4digit)
      end
    end
    @controllers ||= []
    @controllers << OcModuleController.instance
    add_nested_controller(:oc, @controllers.last)
    @controllers.last.open
  end
end