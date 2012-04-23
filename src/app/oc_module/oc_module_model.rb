class OcModuleModel
  attr_accessor :address,
                :controller_klass,
                :text,
                :led_state,
                :up_state,
                :down_state,
                :main_oc,
                :type_sym 

  def initialize(addr="01")
    @address          = addr
    @controller_klass = 'OcModuleController'
    @text             = ''
    @led_state        = :off
    @up_state         = :off
    @down_state       = :off
    @type_sym         = :oc
  end
end
