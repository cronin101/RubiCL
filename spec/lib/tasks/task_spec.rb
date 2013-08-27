require 'spec_helper'

Task = Hadope::Task

describe Task do
  it "is abstract" do
    expect { Task.new }.to raise_error
  end
end
