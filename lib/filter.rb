class HaDope
  class Filter
    include SharedMethods

    def initialize(options = {})
      store [:name, :key, :other_vars, :function, :test], options
    end
  end
end
