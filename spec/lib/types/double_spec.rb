require 'spec_helper'

describe Double do
  it 'defines how to convert from the Ruby Float type to C Doubles' do
    Double.respond_to?(:hadope_conversion).should be true
    dataset = [1.0, 2.0, 3.0]
    Hadope::CPU.get
      .send(Double.hadope_conversion, dataset)[Float]
      .should == dataset
  end
end
