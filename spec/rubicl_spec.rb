require 'spec_helper'

describe RubiCL do
  context 'Showcasing features' do
    it 'can complete an Integer pipeline computation' do
      RubiCL.opencl_device = RubiCL::CPU
      expect do
        [1, 2, 3][Int]
          .map { |i| i + 1 }
          .filter { |i| i > 1 }[Fixnum]
      end.to_not raise_error
    end

    it 'can complete a Double pipeline computation' do
      RubiCL.opencl_device = RubiCL::CPU
      expect do
        [1.0, 2.0, 3.0][Double]
          .map { |j| j + 1.0 }
          .filter { |j| j > 1.5 }[Float]
      end.to_not raise_error
    end

    it 'returns the correct result' do
      [1][Int].map { |i| i + 10 }[Fixnum].should == [11]
      [1, 2, 3][Int].map { |i| i + 1 }[Fixnum].should == [2, 3, 4]
      [1, 2, 3][Int]
        .map { |i| i + 1 }
        .map { |j| j + 2 }
        .map { |k| k + 3 }[Fixnum].should == [7, 8, 9]

      [1, 2][Int].filter { |i| i <= 1 }[Fixnum].should == [1]
      [1, 2, 3][Int].filter { |i| i > 1 }[Fixnum].should == [2, 3]
      [1, 2, 3][Int].filter { |j| j < 3 }[Fixnum].should == [1, 2]

      [1, 2, 3, 4][Int].map { |i| i * 2 }[Fixnum].should == [2, 4, 6, 8]

      [1, 2, 3, 4][Int]
        .map    { |k| k * 2 }
        .filter { |l| l > 4 }[Fixnum].should == [6, 8]

      [1, 2, 3, 4, 5][Int]
        .map    { |m| m * 3 }
        .filter { |n| n >= 9 }
        .map    { |o| o * 10 }
        .filter { |p| p < 140 }[Fixnum].should == [90, 120]

      [1.0, 2.0, 3.0][Double]
        .map { |j| j + 1.1 }
        .filter { |j| j > 2.5 }[Float]
        .should == [3.1, 4.1]
    end

    it 'can #zip and #braid' do
      (1..10)[Int].zip(1..10).braid { |x, y| x - y }[Fixnum].should == (1..10).map { 0 }
    end
  end

  context 'Top level namespace' do
    it 'is defined' do
      expect { RubiCL }.to_not raise_error
    end
  end

  context 'Devices' do
    it 'defines a Device superclass' do
      expect { RubiCL::Device }.to_not raise_error
    end

    it 'defines a CPU device' do
      expect { RubiCL::CPU }.to_not raise_error
    end
  end

  context 'Tasks' do
    it 'defines a TaskQueue' do
      expect { RubiCL::TaskQueue }.to_not raise_error
    end

    it 'defines a Task superclass' do
      expect { RubiCL::Task }.to_not raise_error
    end

    it 'defines a Map task' do
      expect { RubiCL::Map }.to_not raise_error
    end
  end
end
