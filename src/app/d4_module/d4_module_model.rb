class D4ModuleModel
  attr_accessor :address,
                :controller_klass,
                :digits,
                :ledState,
                :addState,
                :subState

  def initialize(addr="01")
    @address          = addr
    @controller_klass = 'D4ModuleController'
    @digits           = '1234'
    @ledState         = :on
    @addState         = :off
    @subState         = :off
    @type_sym         = :d4
  end
end
