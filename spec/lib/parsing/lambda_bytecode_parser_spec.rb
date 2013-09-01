require 'spec_helper'

LambdaBytecodeParser = Hadope::LambdaBytecodeParser

describe LambdaBytecodeParser do
  it "disassembles a lambda" do
    expect { LambdaBytecodeParser.new ->(i){ i * 10 } }.to_not raise_error
    expect { LambdaBytecodeParser.new(->(i){ i }).bytecode }.to_not raise_error
  end

  it "extracts the performed arithmetic operations in Reverse Polish Notation" do
    LambdaBytecodeParser.new(->{ 1 + 2 - 3 }).parsed_operations.should == [1, 2, '+', 3, '-']
    LambdaBytecodeParser.new(->(i){ 1 * (2 + 3 / 4) }).parsed_operations.should == [1, 2, 3, 4, '/', '+', '*']
    expect { LambdaBytecodeParser.new(->{}).translate('some unknown op') }.to raise_error
  end

  it "converts Reverse Polish Notation into Infix Notation" do
    LambdaBytecodeParser.new(->{ 0 }).to_infix.should == [0]
    LambdaBytecodeParser.new(->{ 1 + 2 - 3 }).to_infix.should == ['(1 + 2) - 3']
    LambdaBytecodeParser.new(->(i){ i * (2 + i / 4) }).to_infix.should == ['x * (2 + (x / 4))']
  end

end
