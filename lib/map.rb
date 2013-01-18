class HaDope
  class Map
    include SharedMethods
    include SmartClasses
    include Task

    def initialize(options = {})
      store [:name, :key, :other_vars, :function], options
    end

  end
end
