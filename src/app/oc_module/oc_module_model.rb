class OcModuleModel
  attr_accessor :address, :text, :ledState, :upState, :downState

  def initialize(addr="01")
    @address   = addr
    @text      = 'Testing'
    @ledState  = :on
    @upState   = :off
    @downState = :off
  end
end
