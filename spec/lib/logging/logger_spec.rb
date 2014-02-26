require 'spec_helper'

LOGGER = Hadope::Logger

describe LOGGER do
  it 'is a singleton if accessed using constant' do
    Hadope::LoggerSingleton.get.object_id.should == LOGGER.object_id
  end

  it 'can be set to loud mode' do
    expect { LOGGER.loud_mode }.to_not raise_error
  end

  it 'can be set to quiet mode' do
    expect { LOGGER.quiet_mode }.to_not raise_error
  end
end
