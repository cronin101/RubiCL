require 'spec_helper'

describe Hadope do
  context "Top level namespace" do
    it "is defined" do
      expect { Hadope }.to_not raise_error
    end
  end

  context "Devices" do
    it "defines a Device superclass" do
      expect { Hadope::Device }.to_not raise_error
    end

    it "defines a CPU device" do
      expect { Hadope::CPU }.to_not raise_error
    end
  end

  context "Tasks" do
    it "defines a TaskQueue" do
      expect { Hadope::TaskQueue }.to_not raise_error
    end

    it "defines a Task superclass" do
      expect { Hadope::Task }.to_not raise_error
    end

    it "defines a Map task" do
      expect { Hadope::Map }.to_not raise_error
    end
  end
end
