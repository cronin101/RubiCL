require 'spec_helper'

MAP = Hadope::Map

describe MAP do
  it 'can be created with no statements' do
    expect { MAP.new :footype, :i, [] }.to_not raise_error
  end

  it 'can be created with a single statement' do
    expect { MAP.new(:footype, :i, ['i + 1']) }.to_not raise_error
  end

  it 'can be created with multiple statements' do
    expect { MAP.new(:footype, :i, ['i + 1', 'i + 1']) }.to_not raise_error
  end

  context '#fuse!' do
    it 'should create a pipelining variable when one is needed' do
      fused = MAP.new(:footype, :i, ['i + 1']).fuse! MAP.new(:footype, :j, ['j + 1'])
      fused.instance_variable_get(:@statements).length.should == 3
    end

    it 'should not create a pipelining variable when one is not needed' do
      fused = MAP.new(:footype, :i, ['i + 1']).fuse! MAP.new(:footype, :i, ['i + 1'])
      fused.instance_variable_get(:@statements).length.should == 2
    end
  end
end
