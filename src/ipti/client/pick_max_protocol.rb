require 'eventmachine'
require 'state_machine'
require 'pp'
require 'ipti/protocols'

module IPTI
  module Client
    class PickMaxProtocol < EventMachine::Connection
      include IPTI::PickMaxProtocol

      state_machine :state, :initial => :not_connected do
        after_transition :not_connected => :connected, :do => :connection
#
#      after_failure :on => [:reply_processed, :receive_request], :do => :resend
#
#      event :starting do
#        transition :connected => :initializing
#      end
#
#      event :reset_completed do
#        transition :waiting => :resetting
#      end
#
#      event :send_request do
#        transition [:waiting, :resetting] => :waiting_for_reply
#        transition :initializing => :waiting_for_reply, :if => :is_a_ipti_interface_controller?
#        transition :initializing => :waiting, :unless => :is_a_ipti_interface_controller?
#      end
#
#      event :reply_processed do
#        transition :waiting_for_reply  => :waiting
#      end
#
#      event :receive_request do
##        transition :waiting  => :processing_request
#      end
#
        event :connect do
          transition :not_connected => :connected
        end

#      state :connected do
#      end

#      state :initializing do
#        def boot(sm)
##          self.connection.send_data('', self.address, self.message_types[:reset])
#          if self.is_a_ipti_interface_controller?
#            self.connection.send_data('', self.address, self.message_types[:version])
#            self.connection.send_data('', self.address, self.message_types[:set_polling])
#            self.connection.send_data('', self.address, self.message_types[:set_bays])
#
##            tmp_msg = self.message_types[:set_bays].message(self.address, self.seq)
##            tmp_msg += '0101'
##            self.connection.send_data(tmp_msg, self.address)
#          end
#        end
#      end

#      state :resetting do
#        def boot(sm)
#          self.connection.send_data('', self.address, self.message_types[:set_num_of_devices])
#        end
#      end

#      state :waiting do
#      end

#      state :waiting_for_reply do
#      end
      end
    end
  end
end
