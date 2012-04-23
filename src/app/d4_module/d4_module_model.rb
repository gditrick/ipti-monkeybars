class D4ModuleModel
  attr_accessor :address,
                :controller_klass,
                :digits,
                :led_state,
                :add_state,
                :sub_state,
                :type_sym

  def initialize(addr="01")
    @address          = addr
    @controller_klass = 'D4ModuleController'
    @digits           = ''
    @led_state         = :off
    @add_state         = :off
    @sub_state         = :off
    @type_sym         = :d4
  end
end
