require './extensions/hadope_backend.so'
require 'forwardable'

module Hadope
  require_relative './lib/types/array.rb'
  require_relative './lib/types/fixnum.rb'
  require_relative './lib/types/integer.rb'

  require_relative './lib/logging/logger'

  require_relative './lib/devices/cpu'

  require_relative './lib/tasks/taskqueue'
  require_relative './lib/tasks/map'

  def self.set_device device
    $OpenCLDevice = device
  end

end
