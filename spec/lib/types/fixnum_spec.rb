require 'spec_helper'

describe Fixnum do
  it 'defines how to convert from the equivalent C type (Int)' do
    Fixnum.respond_to?(:hadope_conversion).should be true
    dataset = [1, 2, 3]
    Hadope::CPU.get
      .load_object(:int, dataset)
      .send(Fixnum.hadope_conversion)
      .should == dataset
  end
end
