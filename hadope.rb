require 'hadope_backend'
require 'benchmark'

require_relative './lib/gpu.rb'
require_relative './lib/code_generator.rb'
require_relative './lib/shared_methods.rb'
require_relative './lib/smart_classes.rb'
require_relative './lib/data_set.rb'
class HaDope::Functional
  require_relative './lib/functional/task.rb'
  require_relative './lib/functional/map.rb'
  require_relative './lib/functional/filter.rb'
end
