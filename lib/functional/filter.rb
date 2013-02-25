class HaDope::Functional::Filter
  include HaDope::SharedMethods
  include HaDope::SmartClasses
  include HaDope::Functional::Task

  attr_accessor :test

  def initialize(options = {})
    options[:function] ||= ''
    store [:name, :key, :other_vars, :function, :test], options
  end

end
