class LightGroupModel < AbstractModel
  attr_accessor :controller_klass,
                :height,
                :rows,
                :width

  def initialize
    @rows             = []
    @controller_klass = 'LightGroupController'
  end
end
