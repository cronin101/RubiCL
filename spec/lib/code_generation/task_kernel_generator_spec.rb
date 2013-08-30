require 'spec_helper'

TaskKernelGenerator = Hadope::TaskKernelGenerator

describe TaskKernelGenerator do
  it "can be initialized with a task" do
    expect { TaskKernelGenerator.new Hadope::Map.new(:i, 'i + 1') }.to_not raise_error
  end

  context "Map tasks" do
    it "can generate the kernel from components and boilerplate" do
      map = Hadope::Map.new(:i, 'i + 1')
      map.should_receive(:variable_declarations).once
      map.should_receive(:setup_statements).once
      map.should_receive(:body).once
      map.should_receive(:return_statements).once
      expect { map.to_kernel }.to_not raise_error
    end
  end

  context "Undefined tasks" do
    it "should raise an error when asked to generate the kernel for an undefined task type" do
      class Sometask < Hadope::Task; end
      task = Sometask.new
      generator = TaskKernelGenerator.new task
      expect { generator.create_kernel }.to raise_error
    end
  end
end
