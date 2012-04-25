class AbstractModel
  def self.attr_accessor(*vars)
    @attributes ||= []
    @attributes.concat vars
    super
  end

  def self.attributes
    @attributes
  end

  def attributes
    self.class.attributes
  end
end