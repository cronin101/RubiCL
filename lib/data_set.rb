class HaDope
  class DataSet
    include SharedMethods

    def initialize(options = {})
      store [:name, :type, :data], options
    end
  end
end
