require 'spec_helper'

TASK_KERNEL_GENERATOR = Hadope::TaskKernelGenerator

describe TASK_KERNEL_GENERATOR do
  it 'can be initialized with a task' do
    expect { TASK_KERNEL_GENERATOR.new Hadope::Map.new(:footype, :i, ['i + 1']) }.to_not raise_error
  end

  context 'Map tasks' do
    it 'can generate the kernel from components and boilerplate' do
      map = Hadope::Map.new(:footype, :i, ['i + 1'])
      expect { map.to_kernel }.to_not raise_error
    end
  end

  context 'Filter tasks' do
    it 'can generate the kernel from components and boilerplate' do
      filter = Hadope::Filter.new(:footype, :i, 'i > 1')
      expect { filter.to_kernel }.to_not raise_error
    end
  end

  context 'Undefined tasks' do
    it 'should raise an error when asked to generate the kernel for an undefined task type' do
      class Sometask < Hadope::Task; end
      task = Sometask.new
      generator = TASK_KERNEL_GENERATOR.new task
      expect { generator.create_kernel }.to raise_error
    end
  end
end
