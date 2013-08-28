require 'spec_helper'

describe Hadope do

  context "Showcasing features" do
    it "all features fit together" do
      Hadope.set_device Hadope::CPU
      expect{
        [1,2,3][Integers].map(i:'i + 1')[Fixnums]
      }.to_not raise_error

      pending "has working task dispatch" do
        [1,2,3][Integers].map(i:'i + 1')[Fixnums].should == [2,3,4]
      end
    end
  end

  context "Duck punching" do
    it "extends Array's index-access syntax to shortcut device loading" do
      Hadope.set_device Hadope::CPU
      cpu = Hadope::CPU::get

      [1,2,3][Integers].class.should == cpu.class
      cpu.retrieve_integer_dataset.should == [1,2,3]
    end
  end

  context "Top level namespace" do
    it "is defined" do
      expect { Hadope }.to_not raise_error
    end
  end

  context "Devices" do
    it "defines a Device superclass" do
      expect { Hadope::Device }.to_not raise_error
    end

    it "defines a CPU device" do
      expect { Hadope::CPU }.to_not raise_error
    end
  end

  context "Tasks" do
    it "defines a TaskQueue" do
      expect { Hadope::TaskQueue }.to_not raise_error
    end

    it "defines a Task superclass" do
      expect { Hadope::Task }.to_not raise_error
    end

    it "defines a Map task" do
      expect { Hadope::Map }.to_not raise_error
    end
  end
end
