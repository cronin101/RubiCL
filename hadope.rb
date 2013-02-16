require 'hadope_backend'
require 'benchmark'

class HaDope
  require_relative './lib/code_generator.rb'
  require_relative './lib/shared_methods.rb'
  require_relative './lib/smart_classes.rb'
  require_relative './lib/data_set.rb'
end

class HaDope::OpenCLDevice
  require_relative './lib/devices/opencl_device.rb'
  require_relative './lib/devices/gpu.rb'
  require_relative './lib/devices/cpu.rb'
end

class HaDope::Functional
  require_relative './lib/functional/task.rb'
  require_relative './lib/functional/map.rb'
  require_relative './lib/functional/filter.rb'
end
