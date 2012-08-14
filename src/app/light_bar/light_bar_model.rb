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
end
