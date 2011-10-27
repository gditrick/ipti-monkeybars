require "oc_module_controller"

class LightBarController < ApplicationController
  set_model 'LightBarModel'
  set_view 'LightBarView'
  set_close_action :exit

  def load
    @controllers ||= []
    @controllers << OcModuleController.create_instance
    @controllers.last.open
    add_nested_controller(:oc, @controllers.last)
  end
end
