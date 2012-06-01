class LightGroupModel < AbstractModel
  attr_accessor :controller_klass,
                :rows,
                :width

  def initialize
    @rows            = []
    @controller_klass = 'LightGroupController'
  end
end
