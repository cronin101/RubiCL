require './extensions/hadope_backend.so'

require 'forwardable'

class Array
  alias :old_array_index_access :[]
  def [](index)
    case index
    when Symbol
      $OpenCLDevice::get.send(index, self)
    else
      old_array_index_access(index)
    end
  end
end

Integers = :load_integer_dataset
Fixnums = :retrieve_integer_dataset

module Hadope

  require_relative './lib/devices/cpu'

  require_relative './lib/tasks/taskqueue'

  require_relative './lib/tasks/map'

  def self.set_device device
    $OpenCLDevice = device
  end

end
