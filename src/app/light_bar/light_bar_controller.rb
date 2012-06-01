class LightBarController < ApplicationController
  set_model 'LightBarModel'
  set_view 'LightBarView'
  set_close_action :exit

  def load(*args)
    max_width = 195 + 320 + 20 # sizes of 1 OC Module and
    max_height = 80 + 80 + 20  # 1 D4 Module + 20 for scroll bars
    unless args.compact.empty?
      options = Hash[*args.flatten]
      if options.has_key?(:model)
        model = options[:model]
        update_model(model, *model.attributes)
      end
    end
#pp @__view.screen_size.width
#pp @__view.screen_size.height
    @controllers ||= []
    model.bays.each do |bay|
      c =  eval("#{bay.controller_klass}.create_instance")
      @controllers << c
      add_nested_controller(bay.type_sym, c)
      c.open(:model => bay)
      if bay.light_groupings.nil? or bay.light_groupings.empty?
        current_width  = 0
        current_height = 0
        bay_max_width      = 0  unless bay.devices.nil? or bay.devices.empty?
        bay_max_height     = 80 unless bay.devices.nil? or bay.devices.empty?
        bay.devices.each do |device|
          case device
            when OcModuleModel then width = 320; height = 80
            when D4ModuleModel then width = 195; height = 80
            else width = 320; height = 80
          end
          current_height = height if current_height == 0 or height > current_height
          if current_width + width + 2 > @__view.screen_size.width - 40
            bay_max_height += current_height + 2 if bay_max_height + current_height + 2 < @__view.screen_size.height - 40
            current_width =  0
            current_height = height + 2
          end
          current_width += width + 2
          bay_max_width = current_width + 16 if current_width + 16 > bay_max_width # add fudge factor for different OS
        end
        bay_max_height += current_height if bay_max_height + current_height < @__view.screen_size.height - 40
        max_width  = bay_max_width  if max_width  < bay_max_width
        max_height = bay_max_height if max_height < bay_max_height
      else
        max_width = bay.width > max_width ? bay.width : max_width
      end
    end
    transfer[:preferred_width]  = max_width
    transfer[:preferred_height] = max_height
  end
end