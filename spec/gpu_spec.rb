require 'spec_helper'

describe HaDope::GPU do
  it "allows data to be loaded and retrieved without modifications if no kernel tasks are queued" do
    input_array = (1..1000).to_a
    dataset =  HaDope::DataSet.create({
      name: :test_dataset,
      type: :int,
      data: input_array
    })
    output_array = HaDope::GPU.get.load(:test_dataset).output
    output_array.should eql input_array
  end
end
