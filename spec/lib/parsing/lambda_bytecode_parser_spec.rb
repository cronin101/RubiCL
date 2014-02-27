require 'spec_helper'

LAMBDA_BYTECODE_PARSER = Hadope::LambdaBytecodeParser

describe LAMBDA_BYTECODE_PARSER do
  it 'disassembles an anonymous function by inspecting RubyVM bytecode' do
    expect { LAMBDA_BYTECODE_PARSER.new(->(i){ i }).bytecode }.to_not raise_error
  end

  context 'parsing Ruby bytecode' do
    %w{+ - * / % > < <= >= == !=}.each do |operator|
      it "understands the #{operator} operator" do
        LAMBDA_BYTECODE_PARSER.new(eval "->{ 0 #{operator} 1 }").parsed_operations.should == [0, 1, operator]
      end
    end

    it 'can handle negative numbers' do
      LAMBDA_BYTECODE_PARSER.new(->{ -1 }).parsed_operations.should == [-1]
    end

    it 'can beta-reduce bound variables referenced within closure' do
      foo = 10
      LAMBDA_BYTECODE_PARSER.new(Proc.new { |x| x + foo }).parsed_operations.should == ['x', 10, '+']
    end

    it 'recognises when a bytecode operation is not currently defined' do
      expect { LAMBDA_BYTECODE_PARSER.new(->{ }).send(:translate, 'A_NONEXISTENT_OPERATION') }.to raise_error
    end

    it 'recognises when a bytecode operation is an object method call not currently defined' do
      expect do
        LAMBDA_BYTECODE_PARSER.new(->(i){ i.odd? }).to_infix
      end.to raise_error(RuntimeError, /not implemented for :odd\?/)
    end

    it 'can handle negation' do
      parsed = LAMBDA_BYTECODE_PARSER.new ->(i){ -i  }
      parsed.parsed_operations.should == ['x', :-@]
      parsed.to_infix.should == ['-x']

      LAMBDA_BYTECODE_PARSER.new(->(i){ -((-i) - (-1) - (-2)) }).to_infix.should == ['-((-x) - -1) - -2']
    end

    it 'can handle method-sending #even?' do
      parsed = LAMBDA_BYTECODE_PARSER.new ->(i){ i.even? }
      parsed.parsed_operations.should eq ['x', :even?]
      parsed.to_infix.should eq ['(x % 2 == 0)']
    end
  end

  it 'extracts the performed arithmetic operations in Reverse Polish Notation' do
    LAMBDA_BYTECODE_PARSER.new(->{ 1 + 2 - 3 }).parsed_operations.should == [1, 2, '+', 3, '-']
    ops = LAMBDA_BYTECODE_PARSER.new(->(i){ 1 * (2 + 3 / 4) }).parsed_operations
    ops.should == [1, 2, 3, 4, '/', '+', '*']
    expect { LAMBDA_BYTECODE_PARSER.new(->{ }).translate('some unknown op') }.to raise_error
  end

  it 'converts anonymous functions into C expressions using Infix Notation' do
    LAMBDA_BYTECODE_PARSER.new(->{ 0 }).to_infix.should == [0]
    LAMBDA_BYTECODE_PARSER.new(->{ 1 + 2 - 3 }).to_infix.should == ['(1 + 2) - 3']
    LAMBDA_BYTECODE_PARSER.new(->(i){ i * (2 + i / 4) }).to_infix.should == ['x * (2 + (x / 4))']
  end

end
