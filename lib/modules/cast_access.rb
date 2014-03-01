module Hadope::CastAccess
  def self.included(base)

    begin
      old_behavior = base.instance_method(:[])
    rescue NameError
      old_behavior = nil
    end

    base.class_eval do
      define_method :[] do |index|
        case index
        when Class
          raise 'Must specify OpenCL device with Hadope.set_device' unless Hadope.opencl_device
          raise "#{index.inspect} is not defined as convertible." unless index.respond_to? :hadope_conversion
          Hadope.opencl_device.send(*index.hadope_conversion, self)
        else
          if old_behavior
            old_behavior.bind(self).(index)
          else
            raise NoMethodError
          end
        end
      end
    end
  end
end
