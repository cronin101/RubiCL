require 'spec_helper'

FILTER = Hadope::Filter

describe FILTER do
  it 'cannot be created with no predicate' do
    expect { FILTER.new :footype, :i }.to raise_error
  end

  it 'can be created with a predicate' do
    expect { FILTER.new(:footype, :i, 'i > 1') }.to_not raise_error
  end
end
