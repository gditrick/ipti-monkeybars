class BayModuleModel < AbstractModel
  attr_accessor :address,
                :bay_controller,
                :controller_klass,
                :d4_starting_address,
                :devices,
                :index,
                :light_groupings,
                :lp_starting_address,
                :main_oc,
                :number_of_4d,
                :number_of_lp,
                :type_sym

  def initialize(addr="01")
    @address          = addr
    @controller_klass = 'BayModuleController'
  end
end
