class Hadope::LambdaBytecodeParser < Struct.new(:function)
  LOOKUP_TABLE = {
    opt_plus: '+',
    opt_minus: '-',
    opt_mult: '*',
    opt_div: '/',
    opt_mod: '%',
    opt_lt: '<',
    opt_le: '<=',
    opt_gt: '>',
    opt_ge: '>=',
    opt_eq: '==',
    opt_neq: '!='
  }

  def bytecode
    RubyVM::InstructionSequence.disassemble function
  end

  def locals_table
    eval('local_variables', function.binding)
  end

  def parsed_operations
    operations.map { |o| translate(o) }
  end

  def to_infix
    tokens = parsed_operations
    stack = []
    while tokens.length > 0
      case token = tokens.shift
      when Fixnum, Float then stack.push token
      when Symbol then stack.push method_send(stack.pop, token)
      when String
        if ['x', 'y'].include?(token)
          stack.push(token)
        else
          stack.push(combine(token, stack.pop, stack.pop))
        end
      end
    end

    stack
  end

  private

  def translate(operation)
    case operation
    # First function argument
    when /getlocal_OP__WC__0 #{function.arity + 1}/ then 'x'

    # Second function argument
    when /getlocal_OP__WC__0 #{function.arity}/     then 'y'

    # Indexed bound variable
    when /getlocal_OP__WC__1 \d+/
      id = /WC__1 (?<i>\d+)/.match(operation)[:i].to_i
      index = locals_table.length - (id - 1)
      beta_reduction locals_table[index]

    # Named bound variable
    when /getlocal\s+\w+,\s\d+/
      name = /getlocal\s+(?<name>\w+),/.match(operation)[:name].to_sym
      beta_reduction name

    # Literal Zero
    when /putobject_OP_INT2FIX_O_0_C_/              then 0

    # Literal One
    when /putobject_OP_INT2FIX_O_1_C_/              then 1

    # Floating-Point Literal
    when /putobject\s+-?\d+\.\d+/                   then operation.split(' ').last.to_f

    # Integer Literal
    when /putobject\s+-?\d+/                        then operation.split(' ').last.to_i

    # Method Sending
    when /opt_send_simple/                          then /mid:(?<method>.*?),/.match(operation)[:method].to_sym

    # Built-in Operator
    when /opt_/                                     then LOOKUP_TABLE.fetch operation[/opt_\w+/].to_sym
    else raise "Could not parse: #{operation} in #{bytecode}"
    end
  end

  def beta_reduction variable_name
    function.binding.local_variable_get variable_name
  end

  def method_send(target, method)
    case method
    when :-@ then '-' << target
    when :even? then "(#{target} % 2 == 0)"
    else raise "#method_send not implemented for #{method.inspect}"
    end
  end

  def combine(operator, arg2, arg1)
    "#{enclose arg1} #{operator} #{enclose arg2}"
  end

  def is_value?(token)
    case token
    when Fixnum, Float, *['x', 'y'] then true
    else false
    end
  end

  def enclose(token)
    is_value?(token) ? token : '(' << token << ')'
  end

  def operations
    bytecode.scan(/(?:\d*\s*(?:(getlocal.*|putobject.*|opt_.*).?))/).flatten
  end

end
