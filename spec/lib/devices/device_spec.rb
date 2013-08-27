require 'spec_helper'

Device = Hadope::Device

describe Device do

  it "is abstract" do
    expect { Device.new }.to raise_error
  end

  it "defines transferring an integer array to device memory" do
    Device.instance_methods.include?(:load_integer_dataset).should be true
  end

  it "defines retreiving an integer array from device memory" do
    Device.instance_methods.include?(:retreive_integer_dataset).should be true
  end

  it "creates a task queue when initialized" do
    class SomeDevice < Device; end;
    SomeDevice.new.instance_variable_get(:@task_queue).should_not be nil
  end

end
