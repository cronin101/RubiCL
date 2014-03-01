require 'spec_helper'

GPU = Hadope::GPU

describe GPU do
  it 'is a singleton if accessed using ::get' do
    GPU.get.object_id.should == GPU.get.object_id
  end

  it 'can succesfully load an integer dataset' do
    Hadope::Config::Features.use_host_mem = false
    expect { GPU.get.load_object :int, [1, 2, 3] }.to_not raise_error
  end

  it 'can successfully pin an integer dataset' do
    Hadope::Config::Features.use_host_mem = true
    expect { GPU.get.load_object :int, [1, 2, 3] }.to_not raise_error
  end

  it 'can succesfully retrieve an integer dataset' do
    Hadope::Config::Features.use_host_mem = false
    GPU.get.load_object :int, [1, 2, 3]
    GPU.get.instance_eval { @buffer.invalidate_cache }
    GPU.get.retrieve_integers.should == [1, 2, 3]
  end

  it 'can successfully retrieve a pinned integer dataset' do
    Hadope::Config::Features.use_host_mem = true
    GPU.get.load_object :int, [1, 2, 3]
    GPU.get.instance_eval { @buffer.invalidate_cache }
    GPU.get.retrieve_integers.should == [1, 2, 3]
  end

  it 'allows loading and retrieving via square-bracket syntax' do
    Hadope.opencl_device = GPU
    [1, 2, 3][Int][Fixnum].should == [1, 2, 3]
  end
end
