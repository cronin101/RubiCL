require 'spec_helper'

GPU = Hadope::CPU

describe GPU do
  it 'is a singleton if accessed using ::get' do
    GPU.get.object_id.should == GPU.get.object_id
  end

  it 'can succesfully load an integer dataset' do
    expect { GPU.get.load_integer_dataset [1, 2, 3] }.to_not raise_error
  end

  it 'can successfully pin an integer dataset' do
    expect { GPU.get.pin_integer_dataset [1, 2, 3] }.to_not raise_error
  end

  it 'can succesfully retrieve an integer dataset' do
    GPU.get.load_integer_dataset [1, 2, 3]
    GPU.get.instance_eval { @cache.dataset = nil }
    GPU.get.retrieve_integer_dataset.should == [1, 2, 3]
  end

  it 'can successfully retrieve a pinned integer dataset' do
    GPU.get.pin_integer_dataset [1, 2, 3]
    GPU.get.instance_eval { @cache.dataset = nil }
    GPU.get.retrieve_pinned_integer_dataset.should == [1, 2, 3]
  end

  it 'allows loading and retrieving via square-bracket syntax' do
    Hadope.opencl_device = GPU
    [1, 2, 3][Int][Fixnum].should == [1, 2, 3]
  end
end
