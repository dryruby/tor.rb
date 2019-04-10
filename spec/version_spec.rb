require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'Tor::VERSION' do
  it "matches the VERSION file" do
    expect(Tor::VERSION.to_s) == File.read(File.join(File.dirname(__FILE__), '..', 'VERSION')).chomp
  end
end
