module HaDope::SharedMethods
  attr_accessor :name

  def store_key(key)
    key_types = [:int]
    raise "No key defined" unless key
    raise "Key must be defined as a tuple of [type,name]" unless key.is_a?(Array) && key.size == 2
    raise "Unsupported key type" unless key_types.include? key.first
    @key = { type: key.first, name: key.last }
  end

  def store_function(fn)
    raise "No function defined" unless fn
    raise "Function must be provided as a string of OpenCL code" unless fn.is_a?(String)
    @function = fn
  end

  def store_name(name)
    raise "No kernel name defined" unless name
    raise "Kernel name has already been used" if HaDope::Functional::Map[name] || HaDope::Functional::Filter[name]
    @name = name
  end

  def store_test(test)
    raise "No test defined" unless test
    raise "Test must be provided as one OpenCL statement that can fit inside an if statement" unless test.is_a?(String)
    @test = test
  end

  def store_type(type)
    data_types = [:int]
    raise "No type defined" unless type
    raise "Unsupported data type" unless data_types.include? type
    @type = type
  end

  def store_data(data)
    @data = { size: data.size, values: data }
  end

  def store_other_vars(vars)
    @vars = {}
    vars.to_a.each do |var|
      raise "Each additional variable must be defined as a tuple of [type,name]" unless var.is_a?(Array) && var.size == 2
      type, name = var
      raise "Variable #{name} already defined" if @vars[name]
      @vars[name] = type
    end
  end

  def store(names, options)
    names.each { |name| self.send("store_#{name.to_s}", options[name]) }
  end

end
