require 'spec_helper'

TASK = RubiCL::Task

describe TASK do
  it 'is abstract' do
    expect { TASK.new }.to raise_error
  end

  it 'can have a single statement added' do
    class SomeTask < TASK; end
    task = SomeTask.new
    statement = 'do something;'
    task.add_statement statement
    task.statements.should == [statement]

    task.add_statement statement
    task.statements.should == [statement] * 2
  end

  it 'can have multiple statements added' do
    class SomeTask < TASK; end
    task = SomeTask.new
    statements = ['do something'] * 2

    task.add_statements statements
    task.statements.should == statements

    task.add_statements statements
    task.statements.should == statements * 2
  end
end
