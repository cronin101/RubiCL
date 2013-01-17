class HaDope
  module Task
    attr_accessor :key, :function

    def c_key_type
      case key[:type]
      when :int
        'int'
      else
        raise "oh fuck"
      end
    end

    def kernel
      HaDope::CodeGenerator.new(self).generate_kernel
    end

  end
end
