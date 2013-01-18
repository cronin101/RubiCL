class HaDope
  class Filter
    include SharedMethods
    include SmartClasses
    include Task

    attr_accessor :test

    def initialize(options = {})
      store [:name, :key, :other_vars, :function, :test], options
    end

  end
end
