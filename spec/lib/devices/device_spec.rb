require 'spec_helper'

Device = Hadope::Device

describe Device do
  it "is abstract" do
    expect { Device.new }.to raise_error
  end

  it "defines transferring an integer array to device memory" do
    Device.instance_methods.include?(:load_integer_dataset).should be true
  end

  it "defines retrieving an integer array from device memory" do
    Device.instance_methods.include?(:retrieve_integer_dataset).should be true
  end

  context "#map" do
    it "is defined" do
      Device.instance_methods.include?(:map).should be true
    end

    it "causes a task to be queued" do
      class SomeDevice < Device; end
      device = SomeDevice.new

      expect { device.map(i:'i + 1') }.to_not raise_error
      device.instance_eval { @task_queue }.size.should be 1

      work_unit = device.instance_eval { @task_queue }.shift
      work_unit.statements.should == ['i = i + 1']
    end
  end

  it "creates a task queue when initialized" do
    class SomeDevice < Device; end
    SomeDevice.new.instance_variable_get(:@task_queue).should_not be nil
  end

  it "allows the output to be retrieved by 'casting' to a Ruby type" do
    class StubDevice < Device; def retrieve_integer_dataset; [1]; end; end

    StubDevice.new[Fixnum].should == [1]
  end
end
