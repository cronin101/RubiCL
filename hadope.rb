require './extensions/hadope_backend.so'
require 'forwardable'

module Hadope
  class << self
    attr_accessor :opencl_device
  end

  require_relative './lib/types/array.rb'
  require_relative './lib/types/fixnum.rb'
  require_relative './lib/types/int.rb'

  require_relative './lib/code_generation/task_kernel_generator.rb'
  require_relative './lib/parsing/lambda_bytecode_parser.rb'

  require_relative './lib/logging/logger'

  require_relative './lib/devices/cpu'

  require_relative './lib/tasks/taskqueue'
  require_relative './lib/tasks/map'

end
