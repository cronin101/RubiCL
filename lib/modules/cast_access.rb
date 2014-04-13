module RubiCL::CastAccess
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
          fail 'Must specify OpenCL device with RubiCL.set_device' unless RubiCL.opencl_device
          fail "#{index.inspect} is not defined as convertible." unless index.respond_to? :rubicl_conversion
          RubiCL.opencl_device.send(*index.rubicl_conversion, self)
        else
          if old_behavior
            old_behavior.bind(self).call(index)
          else
            fail NoMethodError
          end
        end
      end
    end
  end
end
