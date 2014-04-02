module RubiCL::RequireType

  module ClassMethods
    # Experimental method-decorators. Handle with care!
    def requires_type(type, method)
      method_body = instance_method(method)
      define_method method do |*arg, &block|
        check_buffer_type! type
        method_body.bind(self).(*arg, &block)
      end

      method
    end

    def sets_type(type, method)
      method_body = instance_method(method)
      define_method method do |*arg, &block|
        @buffer_type = type
        method_body.bind(self).(*arg, &block)
      end

    method
    end

  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  def check_buffer_type! type
    raise "Type Mismatch! Found #@buffer_type, expected #{type}" unless type == loaded_type
  end

  def loaded_type
    @buffer_type
  end

  def vector_type
    case loaded_type
    when :int     then 'int4'
    when :double  then 'double4'
    else
      raise "No vector_type for #{loaded_type.inspect}"
    end
  end

  def unary_types
    %i{int double}
  end

end
