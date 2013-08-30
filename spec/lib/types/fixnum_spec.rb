require 'spec_helper'

describe Fixnum do
  it "defines how to convert from the equivalent C type (Int)" do
    Fixnum.respond_to?(:hadope_conversion).should be true
    Hadope::CPU::get.load_integer_dataset([1,2,3]).send(Fixnum.hadope_conversion).should == [1,2,3]
  end
end
