class HaDope::DataSet
  attr_accessor :data, :type
  include HaDope::SharedMethods
  include HaDope::SmartClasses

  def initialize(options = {})
    store [:name, :type, :data], options
  end

  def required_memory
    HaDope::GPU.get.size_of(@type.to_s)*@data[:size]
  end

end
