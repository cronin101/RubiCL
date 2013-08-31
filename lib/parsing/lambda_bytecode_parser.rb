class Hadope::LambdaBytecodeParser < Struct.new(:function)

  def bytecode
    RubyVM::InstructionSequence::disassemble function
  end

  def operations
    bytecode.scan(/(?:\d*\s*(?:(getlocal.*|putobject.*|opt_\w+).?))/).flatten
  end

  def parsed_operations
    operations.map { |o| translate(o) }
  end

  def translate(operation)
    case operation
    when /getlocal/ then 'i'
    when /putobject_OP_INT2FIX_O_1_C_/ then 1
    when /putobject\s+\d+/ then operation.split(' ').last.to_i
    when /opt_plus/ then '+'
    when /opt_mult/ then '*'
    when /opt_div/ then '/'
    when /opt_minus/ then '-'
    else
      raise "Could not parse: #{operation}"
    end
  end

  def to_infix
    tokens = parsed_operations
    stack = []
    while tokens.length > 0
      token = tokens.shift
      case token
      when Fixnum then stack.push token
      when String
        if token == 'i'
          stack.push token
        else
          b = stack.pop
          a = stack.pop
          stack.push "(#{a}) #{token} (#{b})"
        end
      end
    end

    stack
  end

end
