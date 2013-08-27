require 'spec_helper'

TaskQueue = Hadope::TaskQueue

describe TaskQueue do
  it "initializes with an empty queue of tasks" do
    queue = TaskQueue.new
    queue.size.should == 0
  end

  context "#simplify" do
    it "can be called when there are no tasks" do
      expect { TaskQueue.new.simplify }.to_not raise_error
    end

    it "can be called when there is only one task" do
      map = Hadope::Map.new(:i, 'i + 1')
      queue = TaskQueue.new
      expect {
        queue.push map
        queue.simplify
      }.to_not raise_error
    end

    context "with consecutive map tasks" do
      it "will perform map fusion" do
        map1 = Hadope::Map.new(:i, 'i = i + 1')
        map2 = Hadope::Map.new(:j, 'j = j + 1')
        queue = TaskQueue.new
        expect {
          queue.push map1
          queue.push map2
          queue.simplify!
        }.to_not raise_error

        queue.size.should be 1
        task = queue.tasks.first
        task.statements.size.should == 3
        task.input_name.should == :i
        task.output_name.should == :j
      end
    end
  end
end