class HaDope
  class Map
    include SharedMethods

    def initialize(options = {})
      store [:name, :key, :function], options
    end
  end
end
