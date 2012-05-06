class LightGroupModel < AbstractModel
  attr_accessor :controller_klass,
                :rows

  def initialize
    @rows            = []
    @controller_klass = 'LightGroupController'
  end
end
