require 'spec_helper'

Map = Hadope::Map

describe Map do
  it "can be created with no statements" do
    expect { Map.new :i }.to_not raise_error
  end

  it "can be created with a single statement" do
    expect { Map.new(:i, 'i + 1') }.to_not raise_error
  end

  it "can be created with multiple statements" do
    expect { Map.new(:i, ['i + 1', 'i + 1']) }.to_not raise_error
  end

  context "#fuse!" do
    it "should create a pipelining variable when one is needed" do
      fused = Map.new(:i, 'i + 1').fuse! Map.new(:j, 'j + 1')
      fused.instance_variable_get(:@statements).length.should == 3
    end

    it "should not create a pipelining variable when one is not needed" do
      fused = Map.new(:i, 'i + 1').fuse! Map.new(:i, 'i + 1')
      fused.instance_variable_get(:@statements).length.should == 2
    end
  end
end
