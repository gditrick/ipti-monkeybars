class OcModuleModel
  attr_accessor :address,
                :controller_klass,
                :text,
                :ledState,
                :upState,
                :downState,
                :main_oc,
                :type_sym 

  def initialize(addr="01")
    @address          = addr
    @controller_klass = 'OcModuleController'
    @text             = 'Testing'
    @ledState         = :off
    @upState          = :off
    @downState        = :off
    @type_sym         = :oc
  end
end
