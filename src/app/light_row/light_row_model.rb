class LightRowModel < AbstractModel
  attr_accessor :controller_klass

  def initialize
    @controller_klass = 'LightRowController'
  end
end
