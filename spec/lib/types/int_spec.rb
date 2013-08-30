require 'spec_helper'

describe Int do
  it "defines how to convert from the Ruby Fixnum type to C Ints" do
    Int.respond_to?(:hadope_conversion).should be true
    Hadope::CPU::get.send(Int.hadope_conversion, [1,2,3])[Fixnum].should == [1,2,3]
  end
end
