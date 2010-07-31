require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'Tor::VERSION' do
  it "should match the VERSION file" do
    Tor::VERSION.to_s.should == File.read(File.join(File.dirname(__FILE__), '..', 'VERSION')).chomp
  end
end
