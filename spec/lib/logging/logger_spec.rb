require 'spec_helper'

LOGGER = Hadope::Logger

describe LOGGER do
  it 'is a singleton if accessed using ::get' do
    LOGGER.get.object_id.should == LOGGER.get.object_id
  end

  it 'can be set to loud mode' do
    expect { LOGGER.get.loud_mode }.to_not raise_error
  end

  it 'can be set to quiet mode' do
    expect { LOGGER.get.quiet_mode }.to_not raise_error
  end
end
