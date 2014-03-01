require 'spec_helper'

describe Array do
  it 'has monkey-patched index-access syntax to shortcut device loading' do
    Hadope.opencl_device = Hadope::CPU
    cpu = Hadope::CPU.get

    [1, 2, 3][Int].class.should == cpu.class
    cpu.retrieve_integers.should == [1, 2, 3]
  end

  it "doesn't allow classes without a conversion method defined to be cast" do
    expect { [1, 2, 3][Symbol] }.to raise_error
  end

  it 'still allows the classic behaviour of index-access' do
    [1, 2, 3][1].should == 2
    [1, 2, 3][1..-1].should == [2, 3]
  end
end
