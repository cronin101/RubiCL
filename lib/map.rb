class HaDope
  class Map
    include SharedMethods

    def initialize(options = {})
      store [:name, :key, :other_vars, :function], options
    end
  end
end
