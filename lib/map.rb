class HaDope
  class Map
    include SharedMethods
    include Task

    def initialize(options = {})
      store [:name, :key, :other_vars, :function], options
    end

  end
end
