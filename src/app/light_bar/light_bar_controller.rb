class LightBarController < ApplicationController
  set_model 'LightBarModel'
  set_view 'LightBarView'
  set_close_action :exit

  add_listener :type => :window, :components => [:java_window]

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

  def close_menu_item_action_performed
    unless model.app.configuration_file.nil?
      pp "Closing current configuration"
      model.app.dont_try_connecting
      EM::stop_event_loop
      @controllers.each do |ctl|
        remove_nested_controller(:bay, ctl)
      end
      transfer[:preferred_width]  = 195 + 2 + 320 + APP_SCROLLBAR_WIDTH # sizes of 1 OC Module and
      transfer[:preferred_height] = APP_MENU_HEIGHT + APP_STATUS_HEIGHT + 80 + 2 + 80 + APP_SCROLLBAR_HEIGHT  # 1 D4 Module + 20 for scroll bars
      update_view
#      model.app.configuration.model.bays.each do |bay|
#        bay.devices.each do |device|
#        end
#      end
    end
  end

  def save_menu_item_action_performed
    unless model.app.configuration_file.nil?
      pp "Saving config to file #{model.app.configuration_file}"
      dump_configuration(model.app.configuration_file)
      model.app.configuration_updated
    end
  end

  def save_as_menu_item_action_performed
    file_filter  = javax.swing.filechooser.FileNameExtensionFilter.new("YAML configuration file", "yaml", "yml")
    file_chooser = javax.swing.JFileChooser.new

    file_chooser.file_filter = file_filter
    file_chooser.current_directory = Java::JavaIO.File.new(Dir.pwd)
    file_chooser.dialog_type = javax.swing.JFileChooser::SAVE_DIALOG
    file_chooser.selected_file = Java::JavaIO.File.new(model.app.configuration_file)

    if file_chooser.show_dialog(@main_view_component, "Save") == javax.swing.JFileChooser::APPROVE_OPTION
      pp "Saving config to file #{file_chooser.selected_file.absolute_path}"
      model.app.configuration_file = file_chooser.selected_file.absolute_path
      dump_configuration(model.app.configuration_file)
    end
  end

  def exit_menu_item_action_performed
    window_closing
    window_closed
  end

  def window_closing
    EM::stop_event_loop
  end

  def window_closed
    Java::JavaLang::System.exit(0)
  end

#  alias java_window_closing exit_menu_item_action_performed

#  alias frame_window_closing exit_menu_item_action_performed

  def connect_menu_item_action_performed
    model.app.try_connecting
  end

  def disconnect_menu_item_action_performed
    model.app.dont_try_connecting
  end

  def interface_configure_menu_item_action_performed
    controller =  InterfaceConfigurationController.instance
    @controllers << controller unless @controllers.include?(controller)
    add_nested_controller(:interface_configure, controller)
    controller.open(:model => model)
    if model.remote_host_ip != model.app.configuration.model.remote_host_ip or
       model.remote_host_port != model.app.configuration.model.remote_host_port
      model.app.configuration.model.remote_host_ip   = model.remote_host_ip
      model.app.configuration.model.remote_host_port = model.remote_host_port
      model.app.interface_controller.connection.close_connection unless model.app.interface_controller.connection.nil?
    end
  end

  private

  def dump_configuration(file_name)
    file = File.new(file_name, "w")
    YAML.dump({'configuration' => model.app.configuration}, file)
    file.close
  end
end