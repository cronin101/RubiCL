require 'spec_helper'

SCAN = Hadope::Scan

describe SCAN do
  it 'can be created with no arguments and will default to exclusive prefix-sum' do
    scan = SCAN.new
    scan.statements.should eq ['r = r + e']
    scan.style.should be :exclusive
  end

end
