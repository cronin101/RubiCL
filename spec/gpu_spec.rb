require 'spec_helper'

describe HaDope::GPU do
  context "Functional features" do
    before(:all) do
      FP = HaDope::Functional

      @input_array = (1..100).to_a
      HaDope::DataSet.create( name: :test_dataset,
                              type: :int,
                              data: @input_array  )

      FP::Map.create( name: :test_task,
                      key: [:int, :i],
                      function: 'i++;'  )

      FP::Map.create( name: :inverse_test_task,
                      key: [:int, :i],
                      function: 'i--;'  )

      HaDope::GPU.get
    end

    it "allows data to be loaded and retrieved without modifications if no kernel tasks are queued" do
      gpu = HaDope::GPU.get
      output_array = gpu.load(:test_dataset).output
      output_array.should eql @input_array
    end

    it "remembers a dataset without chaining" do
      gpu = HaDope::GPU.get
      gpu.load(:test_dataset)
      output_array = gpu.output
      output_array.should eql @input_array
    end

    it "allows a map function to be executed on all data correctly" do
      gpu = HaDope::GPU.get
      output_array = gpu.load(:test_dataset).fp_map(:test_task).output
      ruby_map = @input_array.map { |i| i + 1 }
      output_array.should eql ruby_map
    end

    it "allows multiple map functions to be chained correctly" do
      gpu = HaDope::GPU.get
      output_array = gpu.load(:test_dataset).fp_map(:test_task,:inverse_test_task).output
      output_array.should eql @input_array
    end
  end
end
