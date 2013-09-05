require 'spec_helper'

TASK_QUEUE = Hadope::TaskQueue

describe TASK_QUEUE do
  it 'initializes with an empty queue of tasks' do
    queue = TASK_QUEUE.new
    queue.size.should == 0
  end

  context '#simplify!' do
    it 'can be called when there are no tasks' do
      expect { TASK_QUEUE.new.simplify! }.to_not raise_error
    end

    it 'should leave the queued tasks alone when they are not combinable' do
      class SomeTask < Hadope::Task; end
      not_map = SomeTask.new
      map = Hadope::Map.new ->(i){ i + 1 }

      queue = TASK_QUEUE.new
      expect do
        queue.push not_map
        queue.push map
        queue.push map
        queue.simplify!
      end.to_not raise_error

      queue.size.should == 2
    end

    it 'can be called when there is only one task' do
      map = Hadope::Map.new(:i, 'i + 1')
      queue = TASK_QUEUE.new
      expect do
        queue.push map
        queue.simplify!
      end.to_not raise_error
    end

    context 'with consecutive map tasks' do
      it 'will perform map fusion' do
        map1 = Hadope::Map.new(:i, 'i = i + 1')
        map2 = Hadope::Map.new(:j, 'j = j + 1')
        queue = TASK_QUEUE.new
        expect do
          queue.push map1
          queue.push map2
          queue.simplify!
        end.to_not raise_error

        queue.size.should be 1
        task = queue.tasks.first
        task.statements.size.should == 3
        task.input_variable.should == :i
        task.output_variable.should == :j
      end
    end
  end
end
