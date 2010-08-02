module Tor
  ##
  # Tor configuration.
  #
  # @example Parsing a Tor configuration file (1)
  #   torrc = Tor::Config.load("/etc/tor/torrc")
  #
  # @example Parsing a Tor configuration file (2)
  #   Tor::Config.open("/etc/tor/torrc") do |torrc|
  #     puts "Tor SOCKS port: #{torrc['SocksPort']}"
  #     puts "Tor control port: #{torrc['ControlPort']}"
  #     puts "Tor exit policy:"
  #     torrc.each('ExitPolicy') do |key, value|
  #       puts "  #{value}"
  #     end
  #   end
  #
  # @see   https://www.torproject.org/tor-manual.html.en
  # @since 0.1.2
  class Config
    CONFDIR = '/etc/tor' unless defined?(CONFDIR)

    ##
    # Opens a Tor configuration file.
    #
    # @param  [String, #to_s]          filename
    # @param  [Hash{Symbol => Object}] options
    # @yield  [config]
    # @yieldparam [Config] config
    # @return [Config]
    def self.open(filename, options = {}, &block)
      if block_given?
        block.call(self.load(filename, options))
      else
        self.load(filename, options)
      end
    end

    ##
    # Loads the configuration options from a Tor configuration file.
    #
    # @param  [String, #to_s]          filename
    # @param  [Hash{Symbol => Object}] options
    # @return [Config]
    def self.load(filename, options = {})
      self.new(options) do |config|
        File.open(filename.to_s, 'rb') do |file|
          file.each_line do |line|
            case line = line.strip.chomp.strip
              when ''   then next # skip empty lines
              when /^#/ then next # skip comments
              else line = line.split('#').first.strip
            end
            # TODO: support for unquoting and unescaping values
            config << line.split(/\s+/, 2)
          end
        end
      end
    end

    ##
    # @param  [Hash{Symbol => Object}] options
    # @yield  [config]
    # @yieldparam [Config] config
    def initialize(options = {}, &block)
      @lines, @options = [], options.dup
      block.call(self) if block_given?
    end

    ##
    # Appends a new configuration option.
    #
    # @param  [Array(String, String)]
    # @return [Config]
    def <<(kv)
      @lines << kv
      self
    end

    ##
    # Looks up the last value of a particular configuration option.
    #
    # @param  [String, Regexp] key
    # @return [String]
    def [](key)
      values = each(key).map(&:last)
      values.empty? ? nil : values.last
    end

    ##
    # Enumerates configuration options.
    #
    # @param  [String, Regexp] key
    # @yield  [key, value]
    # @yieldparam [String] key
    # @yieldparam [String] value
    # @return [Enumerator]
    def each(key = nil, &block)
      return enum_for(:each, key) unless block_given?
      key ? @lines.find_all { |k, v| key === k }.each(&block) : @lines.each(&block)
    end
  end
end
