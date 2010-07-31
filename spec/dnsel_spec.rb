require File.join(File.dirname(__FILE__), 'spec_helper')

describe Tor::DNSEL do
  before :all do
    $VERBOSE = nil # silence 'warning: already initialized constant' notices
    Resolv::DNS::Config::InitialTimeout = (ENV['TIMEOUT'] || 0.01).to_f
  end

  describe "Tor::DNSEL.include?" do
    it "returns true for exit nodes" do
      Tor::DNSEL.include?('208.75.57.100').should be_true
    end

    it "returns false for non-exit nodes" do
      Tor::DNSEL.include?('1.2.3.4').should be_false
    end

    it "returns nil on DNS timeouts" do
      begin
        Tor::DNSEL::RESOLVER = Resolv::DNS.new
        class << Tor::DNSEL::RESOLVER
          def each_address(host, &block)
            raise Resolv::ResolvTimeout
          end
        end
        Tor::DNSEL.include?('1.2.3.4').should be_nil
      ensure
        Tor::DNSEL::RESOLVER = Resolv::DefaultResolver
      end
    end
  end

  describe "Tor::DNSEL.query" do
    it "returns '127.0.0.2' for exit nodes" do
      Tor::DNSEL.query('208.75.57.100').should == '127.0.0.2'
    end

    it "raises ResolvError for non-exit nodes" do
      lambda { Tor::DNSEL.query('1.2.3.4') }.should raise_error(Resolv::ResolvError)
    end
  end

  describe "Tor::DNSEL.dnsname without options" do
    it "returns the correct DNS name" do
      Tor::DNSEL.dnsname('1.2.3.4').should == '4.3.2.1.53.8.8.8.8.ip-port.exitlist.torproject.org'
    end
  end

  describe "Tor::DNSEL.dnsname with a target port" do
    it "returns the correct DNS name" do
      Tor::DNSEL.dnsname('1.2.3.4', :port => 25).should == '4.3.2.1.25.8.8.8.8.ip-port.exitlist.torproject.org'
    end
  end

  describe "Tor::DNSEL.dnsname with a target IP address" do
    it "returns the correct DNS name" do
      Tor::DNSEL.dnsname('1.2.3.4', :addr => '8.8.4.4').should == '4.3.2.1.53.4.4.8.8.ip-port.exitlist.torproject.org'
    end
  end

  describe "Tor::DNSEL.dnsname with a target IP address and port" do
    it "returns the correct DNS name" do
      Tor::DNSEL.dnsname('1.2.3.4', :addr => '8.8.4.4', :port => 25).should == '4.3.2.1.25.4.4.8.8.ip-port.exitlist.torproject.org'
    end
  end

  describe "Tor::DNSEL.getaddress" do
    it "resolves IPv4 addresses" do
      Tor::DNSEL.getaddress('127.0.0.1').should == '127.0.0.1'
      Tor::DNSEL.getaddress(IPAddr.new('127.0.0.1')).should == '127.0.0.1'
    end

    it "resolves local hostnames" do
      Tor::DNSEL.getaddress('localhost').should == '127.0.0.1'
    end

    it "resolves public hostnames" do
      Tor::DNSEL.getaddress('google.com').should match(Resolv::IPv4::Regex)
    end

    it "raises ArgumentError for IPv6 addresses" do
      lambda { Tor::DNSEL.getaddress('::1') }.should raise_error(ArgumentError)
      lambda { Tor::DNSEL.getaddress(IPAddr.new('::1')) }.should raise_error(ArgumentError)
    end

    it "raises ResolvError for nonexistent hostnames" do
      lambda { Tor::DNSEL.getaddress('foo.example.org') }.should raise_error(Resolv::ResolvError)
    end
  end
end
