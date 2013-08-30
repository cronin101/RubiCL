require 'spec_helper'

describe Hadope do
  context "Showcasing features" do
    it "all features fit together" do
      Hadope.set_device Hadope::CPU
      expect{
        [1,2,3][Int].map(i:'i + 1')[Fixnum]
      }.to_not raise_error
    end

    it "returns the correct result" do
      [1][Int].map(i:'i + 10')[Fixnum].should == [11]
      [1,2,3][Int].map(i:'i + 1')[Fixnum].should == [2,3,4]
      [1,2,3][Int]
        .map(i:'i + 1')
        .map(j:'j + 2')
        .map(k:'k + 3')[Fixnum].should == [7,8,9]
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
