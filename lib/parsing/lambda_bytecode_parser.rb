class Hadope::LambdaBytecodeParser < Struct.new(:function)

  def bytecode
    RubyVM::InstructionSequence::disassemble function
  end

  def parsed_operations
    operations.map { |o| translate(o) }
  end

  def to_infix
    tokens = parsed_operations
    stack = []
    while tokens.length > 0
      token = tokens.shift
      case token
      when Fixnum then stack.push token
      when Symbol then stack.push method_send(stack.pop, token)
      when String
        if token == 'x'
          stack.push token
        else
          b = stack.pop
          a = stack.pop
          stack.push combine(token, a, b)
        end
      end
    end

    stack
  end

  private

  def translate(operation)
    lookup_table = {
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

    case operation
    when /getlocal/ then 'x'
    when /putobject_OP_INT2FIX_O_0_C_/ then 0
    when /putobject_OP_INT2FIX_O_1_C_/ then 1
    when /putobject\s+-?\d+/ then operation.split(' ').last.to_i
    when /opt_send_simple/ then operation.scan(/(?:mid:(.*?),)/)[0][0].to_sym
    when /opt_/ then lookup_table.fetch operation[/opt_\w+/].to_sym
    else
      raise "Could not parse: #{operation}"
    end
  end

  def method_send(target, method)
    case method
    when :-@ then '-' << target
    else
      raise "#method_send not implemented for #{method.inspect}"
    end
  end

  def combine(operator, arg1, arg2)
   "#{enclose arg1} #{operator} #{enclose arg2}"
  end

  def is_value?(token)
    case token
    when Fixnum then true
    when 'x' then true
    else
      false
    end
  end

  def enclose(token)
    is_value?(token) ? token : '(' << token << ')'
  end

  def operations
    bytecode.scan(/(?:\d*\s*(?:(getlocal.*|putobject.*|opt_.*).?))/).flatten
  end

end
