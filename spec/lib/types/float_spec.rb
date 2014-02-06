require 'spec_helper'

describe Float do
  it 'defines how to convert from the equivalent C type (double)' do
    Float.respond_to?(:hadope_conversion).should be true
    dataset = [1.0, 2.0, 3.0]
    Hadope::CPU.get
      .load_double_dataset(dataset)
      .send(Float.hadope_conversion)
      .should == dataset
  end
end
