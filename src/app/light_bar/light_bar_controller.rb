class LightBarController < ApplicationController
  set_model 'LightBarModel'
  set_view 'LightBarView'
  set_close_action :exit

  def load(*args)
    max_width = 195 + 2 + 320 + APP_SCROLLBAR_WIDTH # sizes of 1 OC Module and
    max_height = 80 + 2 + 80 + APP_SCROLLBAR_HEIGHT  # 1 D4 Module + 20 for scroll bars
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
          if current_width + width + 2 > @__view.screen_size.width - APP_SCREEN_REMAIN_WIDTH
            bay_max_height += current_height + 2 if bay_max_height + current_height + 2 < @__view.screen_size.height - APP_SCREEN_REMAIN_HEIGHT
            current_width =  0
            current_height = height + 2
          end
          current_width += width + 2
          bay_max_width = current_width + APP_WIDTH_FUDGE if current_width + APP_WIDTH_FUDGE > bay_max_width # add fudge factor for different OS
        end
        bay_max_height += current_height if bay_max_height + current_height < @__view.screen_size.height - APP_SCREEN_REMAIN_HEIGHT
        max_width  = bay_max_width  if max_width  < bay_max_width
        max_height = bay_max_height if max_height < bay_max_height
      else
        max_width  = bay.width > max_width ? bay.width : max_width
        max_height = bay.height > max_height ? bay.height : max_height
      end
    end
    transfer[:bays_tab_pane_width]  = max_width
    transfer[:bays_tab_pane_height] = max_height
    transfer[:preferred_width]  = max_width
    transfer[:preferred_height] = max_height + APP_MENU_HEIGHT + APP_STATUS_HEIGHT
  end

  def update_message_label(msg="")
    model.status_message = msg
    update_view
  end

  def update_last_sent_text(pick_max_message)
    model.last_sent_message = ""
    unless pick_max_message.nil?
      model.last_sent_message = "Ctl:%s  Type:%s(%s)" % [pick_max_message.controller.address,
                                                         pick_max_message.message_type.type.to_s.upcase,
                                                         pick_max_message.message_type.code.to_s]
    end
    update_view
  end

  def update_last_recv_text(pick_max_message)
    model.last_recv_message = ""
    unless pick_max_message.nil?
      model.last_recv_message = "Ctl:%s  Type:%s(%s)" % [pick_max_message.controller.address,
                                                         pick_max_message.message_type.type.to_s.upcase,
                                                         pick_max_message.message_type.code.to_s]
    end
    update_view
  end

  def exit_menu_item_action_performed
    EM::stop_event_loop
    Java::JavaLang::System.exit(0)
  end

  def connect_menu_item_action_performed
    model.app.try_connecting
  end

  def disconnect_menu_item_action_performed
    model.app.dont_try_connecting
  end
end