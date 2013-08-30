require 'spec_helper'

Logger = Hadope::Logger

describe Hadope::Logger do
  it "is a singleton if accessed using ::get" do
    Logger::get.object_id.should == Logger::get.object_id
  end

  it "can be set to loud mode" do
    expect {Logger::get.loud_mode }.to_not raise_error
  end

  it "can be set to quiet mode" do
    expect { Logger::get.quiet_mode }.to_not raise_error
  end
end
