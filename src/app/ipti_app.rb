require 'eventmachine'
require 'ipti'
require 'client/interface_controller'
require 'client/pick_max_protocol'

class IPTIApp
  attr_accessor :light_bar, :connected, :interface_controller, :try_connect

  def initialize(*args)
    @light_bar = LightBarModel.new
    unless args.compact.empty?
      options = Hash[*args.flatten]
      if options.has_key?(:light_bar)
        @light_bar = options[:light_bar]
      end
      if options.has_key?(:remote_host_ip)
        @light_bar.remote_host_ip = options[:remote_host_ip]
      end
      if options.has_key?(:remote_host_port)
        @light_bar.remote_host_host = options[:remote_host_port]
      end
      if options.has_key?(:bays)
        @light_bar.bays = options[:bays]
      end
    end

    @try_connect = (not @light_bar.remote_host_ip.nil? and not @light_bar.remote_host_port.nil?)

    @connected = false
    @interface_controller = IPTI::Client::InterfaceController.new('EF')
  end

  def connected?
    @connected
  end

  def disconnected?
    not @connected
  end

  def try_connecting?
    @try_connect
  end

  def try_connecting
    @try_connection_timer.cancel unless @try_connection_timer.nil?
    @try_connect = (not @light_bar.remote_host_ip.nil? and not @light_bar.remote_host_port.nil?)
    connect if disconnected? and try_connecting?
    @try_connection_timer = EM::PeriodicTimer.new(5) do
       connect if disconnected? and try_connecting?
    end
  end

  def dont_try_connecting
    @try_connection_timer.cancel unless @try_connection_timer.nil?
    @try_connection_timer = nil
    @try_connect = false
    @interface_controller.connection.close_connection unless @interface_controller.connection.nil?
  end

  def connect
    if try_connecting?
      puts "Try connecting to #{@light_bar.remote_host_ip}:#{@light_bar.remote_host_port}"
      @light_bar.status_message = "Trying to connect to #{@light_bar.remote_host_ip}:#{@light_bar.remote_host_port}"
      EM::connect(@light_bar.remote_host_ip, @light_bar.remote_host_port, IPTI::Client::PickMaxProtocol, self)
      LightBarController.instance.update_message_label(@light_bar.status_message)
    end
  end
end