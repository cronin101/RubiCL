require 'spec_helper'

LambdaBytecodeParser = Hadope::LambdaBytecodeParser

describe LambdaBytecodeParser do
  it "disassembles an anonymous function by inspecting RubyVM bytecode" do
    expect { LambdaBytecodeParser.new(->(i){ i }).bytecode }.to_not raise_error
  end

  context "parsing Ruby bytecode" do
    %w{+ - * / % > < <= >= == !=}.each do |operator|
      it "understands the #{operator} operator" do
        LambdaBytecodeParser.new(eval "->{ 0 #{operator} 1 }").parsed_operations.should == [0, 1, operator]
      end
    end

    it "can handle negative numbers" do
      LambdaBytecodeParser.new(->{ -1 }).parsed_operations.should == [-1]
    end

    it "recognises when an operation is an object method call not currently defined" do
      expect { LambdaBytecodeParser.new(->(i){ i.even? }).to_infix }.to raise_error(RuntimeError, /not implemented for :even\?/)
    end

    it "can handle negation" do
      parsed = LambdaBytecodeParser.new ->(i){ -i  }
      parsed.parsed_operations.should == ['x', :-@]
      parsed.to_infix.should == ['-x']

      LambdaBytecodeParser.new(->(i){ -((-i) - (-1) - (-2)) }).to_infix.should == ['-((-x) - -1) - -2']
    end
  end

  it "extracts the performed arithmetic operations in Reverse Polish Notation" do
    LambdaBytecodeParser.new(->{ 1 + 2 - 3 }).parsed_operations.should == [1, 2, '+', 3, '-']
    LambdaBytecodeParser.new(->(i){ 1 * (2 + 3 / 4) }).parsed_operations.should == [1, 2, 3, 4, '/', '+', '*']
    expect { LambdaBytecodeParser.new(->{}).translate('some unknown op') }.to raise_error
  end

  it "converts anonymous functions into C expressions using Infix Notation" do
    LambdaBytecodeParser.new(->{ 0 }).to_infix.should == [0]
    LambdaBytecodeParser.new(->{ 1 + 2 - 3 }).to_infix.should == ['(1 + 2) - 3']
    LambdaBytecodeParser.new(->(i){ i * (2 + i / 4) }).to_infix.should == ['x * (2 + (x / 4))']
  end

end
