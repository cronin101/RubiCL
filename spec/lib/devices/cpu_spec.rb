require 'spec_helper'

CPU = Hadope::CPU

describe CPU do
  it "is a singleton if accessed using ::get" do
    CPU::get.object_id.should == CPU::get.object_id
  end

  it "can succesfully load an integer dataset" do
    expect { CPU::get.load_integer_dataset [1,2,3] }.to_not raise_error
  end

  it "can succesfully retrieve an integer dataset" do
    CPU::get.load_integer_dataset [1,2,3]
    CPU::get.retrieve_integer_dataset.should == [1,2,3]
  end

  it "allows loading and retrieving via square-bracket syntax" do
    Hadope::set_device Hadope::CPU
    [1,2,3][Integers][Fixnums].should == [1,2,3]
  end
end