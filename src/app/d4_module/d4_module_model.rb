class D4ModuleModel
  attr_accessor :address, :digits, :ledState, :addState, :subState

  def initialize(addr="01")
    @address   = addr
    @digits    = '1234'
    @ledState  = :on
    @addState  = :off
    @subState  = :off
  end
end
