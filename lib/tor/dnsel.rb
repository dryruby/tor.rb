require 'resolv' unless defined?(Resolv)

module Tor
  ##
  # Tor DNS Exit List (DNSEL) client.
  #
  # Unless the target IP address and port are explicitly specified, the
  # query will be performed using a target IP address of "8.8.8.8" and a
  # target port of 53. These correspond to the DNS protocol port on one of
  # the [Google Public DNS](http://code.google.com/speed/public-dns/)
  # servers, and they are guaranteed to be reachable from Tor's default exit
  # policy.
  #
  # @example Checking source IP addresses
  #   Tor::DNSEL.include?("185.220.101.21")               #=> true
  #   Tor::DNSEL.include?("1.2.3.4")                     #=> false
  #
  # @example Checking source hostnames
  #   Tor::DNSEL.include?("ennui.lostinthenoise.net")    #=> true
  #   Tor::DNSEL.include?("myhost.example.org")          #=> false
  #
  # @example Specifying an explicit target port
  #   Tor::DNSEL.include?("185.220.101.21", :port => 80)  #=> true
  #   Tor::DNSEL.include?("185.220.101.21", :port => 25)  #=> false
  #
  # @example Specifying an explicit target IP address and port
  #   Tor::DNSEL.include?(source_addr, :addr => target_addr, :port => target_port)
  #   Tor::DNSEL.include?("185.220.101.21", :addr => myip, :port => myport)
  #
  # @example Using from a Rack application
  #   Tor::DNSEL.include?(env['REMOTE_ADDR'] || env['REMOTE_HOST'], {
  #     :addr => env['SERVER_NAME'],
  #     :port => env['SERVER_PORT'],
  #   })
  #
  # @see https://www.torproject.org/tordnsel/
  # @see https://trac.torproject.org/projects/tor/wiki/TheOnionRouter/TorDNSExitList
  # @see http://gitweb.torproject.org/tor.git?a=blob_plain;hb=HEAD;f=doc/contrib/torel-design.txt
  module DNSEL
    RESOLVER    = Resolv::DefaultResolver unless defined?(RESOLVER)
    TARGET_ADDR = '8.8.8.8'.freeze        unless defined?(TARGET_ADDR)     # Google Public DNS
    TARGET_PORT = 53                      unless defined?(TARGET_PORT)     # DNS
    DNS_SUFFIX  = 'ip-port.exitlist.torproject.org'.freeze

    ##
    # Returns `true` if the Tor DNSEL includes `host`, `false` otherwise.
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
    # @param  [Hash{Symbol => Object}] options
    # @option options [String, #to_s]  :addr ("8.8.8.8")
    # @option options [Integer, #to_i] :port (53)
    # @return [Boolean]
    def self.include?(host, options = {})
      begin
        query(host, options) == '127.0.0.2'
      rescue Resolv::ResolvError   # NXDOMAIN
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
    # @param  [Hash{Symbol => Object}] options
    # @option options [String, #to_s]  :addr ("8.8.8.8")
    # @option options [Integer, #to_i] :port (53)
    # @return [String]
    # @raise  [Resolv::ResolvError] for an NXDOMAIN response
    def self.query(host, options = {})
      getaddress(dnsname(host, options))
    end

    ##
    # Returns the DNS name used for Tor DNSEL queries of `host`.
    #
    # @example
    #   Tor::DNSEL.dnsname("1.2.3.4")           #=> "4.3.2.1.53.8.8.8.8.ip-port.exitlist.torproject.org"
    #
    # @param  [String, #to_s]          host
    # @param  [Hash{Symbol => Object}] options
    # @option options [String, #to_s]  :addr ("8.8.8.8")
    # @option options [Integer, #to_i] :port (53)
    # @return [String]
    def self.dnsname(host, options = {})
      source_addr = getaddress(host, true)
      target_addr = getaddress(options[:addr] || TARGET_ADDR, true)
      target_port = options[:port] || TARGET_PORT
      [source_addr, target_port, target_addr, DNS_SUFFIX].join('.')
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
