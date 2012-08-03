class LightRowModel < AbstractModel
  attr_accessor :controller_klass,
                :devices,
                :height,
                :width

  def initialize
    @controller_klass = 'LightRowController'
  end
end
