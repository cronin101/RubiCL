require 'spec_helper'

CPU = Hadope::CPU

describe CPU do
  it 'is a singleton if accessed using ::get' do
    CPU.get.object_id.should == CPU.get.object_id
  end

  it 'can succesfully load an integer dataset' do
    Hadope::Config::Features.use_host_mem = false
    expect { CPU.get.load_object :int, [1, 2, 3] }.to_not raise_error
  end

  it 'can successfully pin an integer dataset' do
    Hadope::Config::Features.use_host_mem = true
    expect { CPU.get.load_object :int, [1, 2, 3] }.to_not raise_error
  end

  it 'can succesfully retrieve an integer dataset' do
    Hadope::Config::Features.use_host_mem = false
    CPU.get.load_object :int, [1, 2, 3]
    CPU.get.instance_eval { @buffer.invalidate_cache }
    CPU.get.retrieve_integers.should == [1, 2, 3]
  end

  it 'can successfully retrieve a pinned integer dataset' do
    Hadope::Config::Features.use_host_mem = true
    CPU.get.load_object :int, [1, 2, 3]
    CPU.get.instance_eval { @buffer.invalidate_cache }
    CPU.get.retrieve_integers.should == [1, 2, 3]
  end

  it 'allows loading and retrieving via square-bracket syntax' do
    Hadope.opencl_device = CPU
    [1, 2, 3][Int][Fixnum].should == [1, 2, 3]
  end
end
