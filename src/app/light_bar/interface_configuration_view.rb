class InterfaceConfigurationView < ApplicationView
  set_java_class 'app.light_bar.InterfaceConfigurationDialog'

  map :view => "remote_host_ip_field.text",   :model => :remote_host_ip
  map :view => "remote_host_port_field.text", :model => :remote_host_port, :using => [:convert_to_string, :convert_to_fixnum]

  def convert_to_string(attr)
    attr.to_s
  end

  def convert_to_fixnum(attr)
    remote_host_port_field.text.to_i
  end
end
