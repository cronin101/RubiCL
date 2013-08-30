class Array
  alias :old_array_index_access :[]
  def [](index)
    case index
    when Class
      raise "Must specify OpenCL device with Hadope::set_device" unless $OpenCLDevice
      $OpenCLDevice::get.send(index.hadope_conversion, self)
    else
      old_array_index_access(index)
    end
  end
end

