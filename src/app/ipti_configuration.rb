class IptiConfiguration
  attr_accessor :controller_klass, :model

  def ==(other)
    @controller_klass == other.controller_klass and @model == other.model
  end
end