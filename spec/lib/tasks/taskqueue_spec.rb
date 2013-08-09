require 'spec_helper'

TaskQueue = Hadope::TaskQueue

describe TaskQueue do
  it "initializes with an empty queue of tasks" do
    queue = TaskQueue.new
    queue.size.should == 0
  end
end
