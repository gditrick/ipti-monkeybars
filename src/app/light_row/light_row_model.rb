class LightRowModel < AbstractModel
  attr_accessor :controller_klass,
                :devices,
                :height,
                :width

  def initialize
    @devices = []
    @controller_klass = 'LightRowController'
  end

  def to_yaml_properties
    ["@controller_klass", "@devices"]
  end

  def ==(other)
    @controller_klass == other.controller_klass and
      @devices == other.devices
  end
end
