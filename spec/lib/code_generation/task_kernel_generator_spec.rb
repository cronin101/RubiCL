require 'spec_helper'

TASK_KERNEL_GENERATOR = RubiCL::TaskKernelGenerator

describe TASK_KERNEL_GENERATOR do
  it 'can be initialized with a task' do
    expect { TASK_KERNEL_GENERATOR.new RubiCL::Map.new(:footype, :i, ['i + 1']) }.to_not raise_error
  end

  context 'Map tasks' do
    it 'can generate the kernel from components and boilerplate' do
      map = RubiCL::Map.new(:footype, :i, ['i + 1'])
      expect { map.to_kernel }.to_not raise_error
    end
  end

  context 'Filter tasks' do
    it 'can generate the kernel from components and boilerplate' do
      filter = RubiCL::Filter.new(:footype, :i, 'i > 1')
      expect { filter.to_kernel }.to_not raise_error
    end
  end

  context 'Scan tasks' do
    it 'can generate the kernel from components and boilerplate' do
      expect { RubiCL::Scan.new.to_kernel }.to_not raise_error
    end
  end

  context 'Braid tasks' do
    it 'can generate the kernel from components and boilerplate' do
      braid = RubiCL::Braid.new(:footype, :i, :j, ['i = i + j'])
      expect { braid.to_kernel }.to_not raise_error
    end
  end

  context 'Sort tasks' do
    it 'can generate the kernel from components and boilerplate' do
      sort = RubiCL::Sort.new
      expect { sort.to_kernel }.to_not raise_error
    end
  end

  context 'Undefined tasks' do
    it 'should raise an error when asked to generate the kernel for an undefined task type' do
      class Sometask < RubiCL::Task; end
      task = Sometask.new
      generator = TASK_KERNEL_GENERATOR.new task
      expect { generator.create_kernel }.to raise_error
    end
  end
end
