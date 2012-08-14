class BayModuleModel < AbstractModel
  attr_accessor :address,
                :bay_controller,
                :controller_klass,
                :d4_starting_address,
                :devices,
                :height,
                :index,
                :light_groupings,
                :lp_starting_address,
                :main_oc,
                :number_of_4d,
                :number_of_lp,
                :type_sym,
                :width

  def initialize(addr="01")
    @address          = addr
    @controller_klass = 'BayModuleController'
  end

  def to_yaml_properties
    ["@address",
     "@controller_klass",
     "@d4_starting_address",
     "@devices",
     "@light_groupings",
     "@lp_starting_address",
     "@main_oc",
     "@number_of_4d",
     "@number_of_lp",
     "@type_sym",
    ]
  end

  def ==(other)
    @address == other.address and
      @controller_klass == other.controller_klass and
      @d4_starting_address == other.d4_starting_address and
      @devices == other.devices and
      @light_groupings == other.light_groupings and
      @lp_starting_address == other.lp_starting_address and
      @main_oc == other.main_oc and
      @number_of_4d == other.number_of_4d and
      @number_of_lp == other.number_of_lp
  end
end
