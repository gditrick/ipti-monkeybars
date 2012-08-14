class LightBarModel < AbstractModel
  attr_accessor :app,
                :bays,
                :height,
                :status_message,
                :last_sent_message,
                :last_recv_message,
                :remote_host_ip,
                :remote_host_port,
                :width

  def initialize
    @status_message = "Nothing defined to connect to"
  end

  def to_yaml_properties
    ["@bays", "@remote_host_ip", "@remote_host_port" ]
  end

  def ==(other)
    @remote_host_ip == other.remote_host_ip and
      @remote_host_port == other.remote_host_port and
      @bays == other.bays
  end
end
