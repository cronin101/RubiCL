class Array
  alias :__old_array_index_access :[]
  def [](index)
    case index
    when Class
      raise "Must specify OpenCL device with Hadope::set_device" unless $OpenCLDevice
      raise "#{index.inspect} is not defined as convertible." unless index.respond_to? :hadope_conversion
      $OpenCLDevice::get.send(index.hadope_conversion, self)
    else
      __old_array_index_access(index)
    end
  end
end

