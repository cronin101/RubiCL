require 'spec_helper'

describe File do
  it 'has monkey-patched index-access syntax to shortcut device loading' do
    Hadope.opencl_device = Hadope::CPU
    cpu = Hadope::CPU.get

    File.new('numbers.txt')[Int].class.should == cpu.class
    cpu.retrieve_integer_dataset.should == File.open('numbers.txt').lines.map(&:to_i)
  end

end
