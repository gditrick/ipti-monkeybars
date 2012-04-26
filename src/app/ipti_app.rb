require 'eventmachine'
require 'ipti'
require 'client/pick_max_protocol'

class IPTIApp
  attr_accessor :light_bar, :connected
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
    if @light_bar.remote_host_ip.nil?
      raise 'No remote host ip define to connect to'
    end
    if @light_bar.remote_host_port.nil?
      raise 'No remote host port define to connect to'
    end
    @connected = false
  end

  def connected?
    @connected
  end

  def not_connected?
    not @connected
  end

  def connect
    puts "Try connecting to #{@light_bar.remote_host_ip}:#{@light_bar.remote_host_port}"
    EM::connect(@light_bar.remote_host_ip, @light_bar.remote_host_port, IPTI::Client::PickMaxProtocol)
  end
end