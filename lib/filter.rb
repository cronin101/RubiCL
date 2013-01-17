class HaDope
  class Filter
    include SharedMethods
    include Task

    attr_accessor :test

    def initialize(options = {})
      store [:name, :key, :other_vars, :function, :test], options
    end

  end
end
