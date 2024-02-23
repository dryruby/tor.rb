require 'resolv' unless defined?(Resolv)

module Tor
  module DNSEL
    RESOLVER    = Resolv::DefaultResolver unless defined?(RESOLVER)
    DNS_SUFFIX  = 'dnsel.torproject.org'.freeze

    ##
    # Returns `true` if `host` is a Tor Exit Node, `false` otherwise.
    #
    # If the DNS server is unreachable or the DNS query times out, returns
    # `nil` to indicate that we don't have a definitive answer one way or
    # another.
    #
    # @example
    #   Tor::DNSEL.include?("185.220.101.21")    #=> true
    #   Tor::DNSEL.include?("1.2.3.4")          #=> false
    #
    # @param  [String, #to_s]          host
    # @return [Boolean]
    def self.include?(host)
      begin
        query(host) == '127.0.0.2'
      rescue Resolv::ResolvError # NXDOMAIN
        false
      rescue Resolv::ResolvTimeout
        nil
      rescue Errno::EHOSTUNREACH
        nil
      rescue Errno::EADDRNOTAVAIL
        nil
      end
    end

    ##
    # Queries the Tor DNSEL for `host`, returning "172.0.0.2" if it is an
    # exit node and raising a `Resolv::ResolvError` if it isn't.
    #
    # @example
    #   Tor::DNSEL.query("185.220.101.21")       #=> "127.0.0.2"
    #   Tor::DNSEL.query("1.2.3.4")             #=> Resolv::ResolvError
    #
    # @param  [String, #to_s]          host
    # @return [String]
    # @raise  [Resolv::ResolvError] for an NXDOMAIN response
    def self.query(host)
      getaddress(dnsname(host))
    end

    ##
    # Returns the DNS name used for Tor DNSEL queries of `host`.
    #
    # @example
    #   Tor::DNSEL.dnsname("1.2.3.4")           #=> "4.3.2.1.dnsel.torproject.org"
    #
    # @param  [String, #to_s]          host
    # @return [String]
    def self.dnsname(host)
      source_addr = getaddress(host, true)
      "#{source_addr}.#{DNS_SUFFIX}"
    end
    class << self; alias_method :hostname, :dnsname; end

    protected

    ##
    # Resolves `host` into an IPv4 address using Ruby's default resolver.
    #
    # Optionally returns the IPv4 address with its octet order reversed.
    #
    # @example
    #   Tor::DNSEL.getaddress("ruby-lang.org")  #=> "221.186.184.68"
    #   Tor::DNSEL.getaddress("1.2.3.4")        #=> "1.2.3.4"
    #   Tor::DNSEL.getaddress("1.2.3.4", true)  #=> "4.3.2.1"
    #
    # @param  [String, #to_s] host
    # @param  [Boolean]       reversed
    # @return [String]
    def self.getaddress(host, reversed = false)
      host = case host.to_s
             when Resolv::IPv6::Regex
               raise ArgumentError.new("not an IPv4 address: #{host}")
             when Resolv::IPv4::Regex
               host.to_s
             else
               begin
                 RESOLVER.each_address(host.to_s) do |addr|
                   return addr.to_s if addr.to_s =~ Resolv::IPv4::Regex
                 end
                 raise Resolv::ResolvError.new("no address for #{host}")
               rescue NoMethodError
                 # This is a workaround for Ruby bug #2614:
                 # @see http://redmine.ruby-lang.org/issues/show/2614
                 raise Resolv::ResolvError.new("no address for #{host}")
               end
             end
      reversed ? host.split('.').reverse.join('.') : host
    end
  end
end
