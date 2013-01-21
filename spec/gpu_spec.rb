require 'spec_helper'

describe HaDope::GPU do
  before(:all) do
    @input_array = (1..100).to_a
    HaDope::DataSet.create({
      name: :test_dataset,
      type: :int,
      data: @input_array
    })

kernel =<<C_CODE
i++;
C_CODE

    HaDope::Map.create({
      name: :test_task,
      key: [:int, :i],
      function: kernel
    })

    HaDope::GPU.get
  end

  it "allows data to be loaded and retrieved without modifications if no kernel tasks are queued" do
    output_array = HaDope::GPU.get.load(:test_dataset).output
    output_array.should eql @input_array
  end

  it "allows a map function to be executed on all data correctly" do
    output_array = HaDope::GPU.get.load(:test_dataset).map(:test_task).output
    ruby_map = @input_array.map { |i| i + 1 }
    output_array.should eql ruby_map
  end
end
