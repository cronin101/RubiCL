class Array
  old_behavior = instance_method(:[])
  define_method :[] do |index|
    case index
    when Class
      raise 'Must specify OpenCL device with Hadope.set_device' unless Hadope.opencl_device
      raise "#{index.inspect} is not defined as convertible." unless index.respond_to? :hadope_conversion
      Hadope.opencl_device.send(index.hadope_conversion, self)
    else
      old_behavior.bind(self).(index)
    end
  end
end

