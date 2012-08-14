class LightGroupModel < AbstractModel
  attr_accessor :controller_klass,
                :height,
                :rows,
                :width

  def initialize
    @rows             = []
    @controller_klass = 'LightGroupController'
  end

  def to_yaml_properties
    ["@controller_klass", "@rows"]
  end

  def ==(other)
    @controller_klass == other.controller_klass and
      @rows == other.rows
  end
end
