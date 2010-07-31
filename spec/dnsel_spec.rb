require File.join(File.dirname(__FILE__), 'spec_helper')

describe Tor::DNSEL do
  describe "Tor::DNSEL.include?" do
    # TODO
  end

  describe "Tor::DNSEL.query" do
    # TODO
  end

  describe "Tor::DNSEL.dnsname" do
    # TODO
  end

  describe "Tor::DNSEL.getaddress" do
    it "resolves IPv4 addresses" do
      Tor::DNSEL.getaddress('127.0.0.1').should == '127.0.0.1'
      Tor::DNSEL.getaddress(IPAddr.new('127.0.0.1')).should == '127.0.0.1'
    end

    it "rejects IPv6 addresses" do
      lambda { Tor::DNSEL.getaddress('::1') }.should raise_error(ArgumentError)
      lambda { Tor::DNSEL.getaddress(IPAddr.new('::1')) }.should raise_error(ArgumentError)
    end

    it "resolves local hostnames" do
      Tor::DNSEL.getaddress('localhost').should == '127.0.0.1'
    end

    it "resolves public hostnames" do
      Tor::DNSEL.getaddress('google.com').should match(Resolv::IPv4::Regex)
    end
  end
end
