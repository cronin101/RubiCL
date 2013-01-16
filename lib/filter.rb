class HaDope
  class Filter
    include SharedMethods

    def initialize(options = {})
      store [:name, :key, :function, :test], options
    end
  end
end
