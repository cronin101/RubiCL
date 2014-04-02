require 'spec_helper'

describe Fixnum do
  it 'defines how to convert from the equivalent C type (Int)' do
    Fixnum.respond_to?(:rubicl_conversion).should be true
    dataset = [1, 2, 3]
    RubiCL::CPU.get
      .load_object(:int, dataset)
      .send(Fixnum.rubicl_conversion)
      .should == dataset
  end
end
