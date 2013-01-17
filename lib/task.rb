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
      result = nil
      puts "#{@name.capitalize} kernel generation Time: " << Benchmark.realtime { result = HaDope::CodeGenerator.new(self).generate_kernel }.to_s
      result
    end

  end
end
