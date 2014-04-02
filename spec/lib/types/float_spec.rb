require 'spec_helper'

describe Float do
  it 'defines how to convert from the equivalent C type (double)' do
    Float.respond_to?(:rubicl_conversion).should be true
    dataset = [1.0, 2.0, 3.0]
    RubiCL::CPU.get
      .load_object(:double, dataset)
      .send(Float.rubicl_conversion)
      .should == dataset
  end
end
