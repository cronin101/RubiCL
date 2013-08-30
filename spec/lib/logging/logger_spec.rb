require 'spec_helper'

Logger = Hadope::Logger

describe Hadope::Logger do
  it "is a singleton if accessed using ::get" do
    Logger::get.object_id.should == Logger::get.object_id
  end
end
