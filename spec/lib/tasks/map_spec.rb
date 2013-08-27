require 'spec_helper'

Map = Hadope::Map

describe Map do
  it "can be created with no statements" do
    expect { Map.new :i }.to_not raise_error
  end

  it "can be created with a single statement" do
    expect { Map.new(:i, 'i + 1') }.to_not raise_error
  end

  it "can be created with multiple statements" do
    expect { Map.new(:i, ['i + 1', 'i + 1']) }.to_not raise_error
  end
end
