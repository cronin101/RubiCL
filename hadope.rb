require './extensions/hadope_backend.so'

require 'forwardable'

module Hadope
  require_relative './lib/devices/cpu'

  require_relative './lib/tasks/taskqueue'

  require_relative './lib/tasks/map'
end
