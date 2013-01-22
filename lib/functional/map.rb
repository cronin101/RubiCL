class HaDope::Functional::Map
  include HaDope::SharedMethods
  include HaDope::SmartClasses
  include HaDope::Functional::Task

  def initialize(options = {})
    store [:name, :key, :other_vars, :function], options
  end

end
