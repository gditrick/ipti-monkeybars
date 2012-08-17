class InterfaceConfigurationController < ApplicationController
  set_model 'LightBarModel'
  set_view  'InterfaceConfigurationView'

  set_close_action :close

  def load(*args)
    unless args.compact.empty?
      options = Hash[*args.flatten]
      if options.has_key?(:model)
        @config = options[:model]
        update_model(@config, *@config.attributes)
      end
    end
    raise "No configuration sent to #{self.class.name}" if @config.nil?
  end

  def remote_host_ip_field_key_pressed(event)
    if event.key_code == Java::JavaAwtEvent::KeyEvent::VK_ENTER
      event.component.transfer_focus
    end
  end

  def remote_host_port_field_key_pressed(event)
    if event.key_code == Java::JavaAwtEvent::KeyEvent::VK_ENTER
      event.component.transfer_focus
    end
  end

  def ok_button_action_performed
    @config.remote_host_ip   = view_model.remote_host_ip
    @config.remote_host_port = view_model.remote_host_port
    close
  end

  def  ok_button_key_pressed(event)
    if event.key_code == Java::JavaAwtEvent::KeyEvent::VK_ENTER
      ok_button_action_performed
    end
  end

  def cancel_button_action_performed
    close
  end

  def  cancel_button_key_pressed(event)
    if event.key_code == Java::JavaAwtEvent::KeyEvent::VK_ENTER
      cancel_button_action_performed
    end
  end
end