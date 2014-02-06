require './ext/hadope_backend'
require 'forwardable'

module Hadope
  class << self
    attr_writer :opencl_device
  end

  require_relative './lib/modules/require_type.rb'

  require_relative './lib/types/array.rb'
  require_relative './lib/types/fixnum.rb'
  require_relative './lib/types/float.rb'

  require_relative './lib/types/int.rb'
  require_relative './lib/types/double.rb'

  require_relative './lib/code_generation/task_kernel_generator.rb'
  require_relative './lib/parsing/lambda_bytecode_parser.rb'

  require_relative './lib/logging/logger'

  require_relative './lib/devices/cpu'
#  require_relative './lib/devices/gpu'

  require_relative './lib/tasks/taskqueue'
  require_relative './lib/tasks/map'
  require_relative './lib/tasks/filter'
  require_relative './lib/tasks/braid'

  def self.opencl_device
    @opencl_device.get
  end

end

# Sensible default for now
Hadope.opencl_device = Hadope::CPU
