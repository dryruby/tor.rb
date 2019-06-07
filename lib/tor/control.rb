require 'socket' unless defined?(Socket)

module Tor
  ##
  # Tor Control Protocol (TC) client.
  #
  # The Tor control protocol is used by other programs (such as frontend
  # user interfaces) to communicate with a locally running Tor process. It
  # is not part of the Tor onion routing protocol.
  #
  # @example Establishing a controller connection (1)
  #   tor = Tor::Controller.new
  #
  # @example Establishing a controller connection (2)
  #   tor = Tor::Controller.new(:host => '127.0.0.1', :port => 9051)
  #
  # @example Authenticating the controller connection
  #   tor.authenticate
  #
  # @example Obtaining information about the Tor process
  #   tor.version      #=> "0.2.1.25"
  #   tor.config_file  #=> #<Pathname:/opt/local/etc/tor/torrc>
  #
  # @see   http://gitweb.torproject.org/tor.git?a=blob_plain;hb=HEAD;f=doc/spec/control-spec.txt
  # @see   http://www.thesprawl.org/memdump/?entry=8
  # @since 0.1.1
  class Controller
    PROTOCOL_VERSION = 1

    ##
    # @param  [Hash{Symbol => Object}] options
    # @option options [String, #to_s]  :host    ("127.0.0.1")
    # @option options [Integer, #to_i] :port    (9051)
    # @option options [String, #to_s]  :cookie  (nil)
    # @option options [Integer, #to_i] :version (PROTOCOL_VERSION)
    def self.connect(options = {}, &block)
      if block_given?
        result = block.call(tor = self.new(options))
        tor.quit
        result
      else
        self.new(options)
      end
    end

    ##
    # @param  [Hash{Symbol => Object}] options
    # @option options [String, #to_s]  :host    ("127.0.0.1")
    # @option options [Integer, #to_i] :port    (9051)
    # @option options [String, #to_s]  :cookie  (nil)
    # @option options [Integer, #to_i] :version (PROTOCOL_VERSION)
    def initialize(options = {}, &block)
      @options = options.dup
      @host    = (@options.delete(:host)    || '127.0.0.1').to_s
      @port    = (@options.delete(:port)    || 9051).to_i
      @version = (@options.delete(:version) || PROTOCOL_VERSION).to_i
      connect
      if block_given?
        block.call(self)
        quit
      end
    end

    attr_reader :host, :port

    ##
    # Establishes the socket connection to the Tor process.
    #
    # @example
    #   tor.close
    #   tor.connect
    #
    # @return [void]
    def connect
      close
      @socket = TCPSocket.new(@host, @port)
      @socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, true)
      self
    end

    ##
    # Returns `true` if the controller connection is active.
    #
    # @example
    #   tor.connected?             #=> true
    #   tor.close
    #   tor.connected?             #=> false
    #
    # @return [Boolean]
    def connected?
      !!@socket
    end

    ##
    # Closes the socket connection to the Tor process.
    #
    # @example
    #   tor.close
    #
    # @return [void]
    def close
      @socket.close if @socket
      @socket = nil
      self
    end

    ##
    # Tells the Tor process to hang up on this controller connection.
    #
    # This command can be used before authenticating.
    #
    # @example
    #   C: QUIT
    #   S: 250 closing connection
    #   ^D
    #
    # @example
    #   tor.quit
    #
    # @return [void]
    def quit
      send_line('QUIT')
      reply = read_reply
      close
      reply
    end

    ##
    # Returns information about the authentication method required by the
    # Tor process.
    #
    # This command may be used before authenticating.
    #
    # @example
    #     C: PROTOCOLINFO
    #     S: 250-PROTOCOLINFO 1
    #     S: 250-AUTH METHODS=NULL
    #     S: 250-VERSION Tor="0.2.1.25"
    #     S: 250 OK
    #
    # @example
    #   tor.authentication_method  #=> nil
    #   tor.authentication_method  #=> :hashedpassword
    #   tor.authentication_method  #=> :cookie
    #
    # @return [Symbol]
    # @since  0.1.2
    def authentication_method
      @authentication_method ||= begin
        method = nil
        send_line('PROTOCOLINFO')
        loop do
          # TODO: support for reading multiple authentication methods
          case reply = read_reply
            when /^250-AUTH METHODS=(\w*)/
              method = $1.strip.downcase.to_sym
              method = method.eql?(:null) ? nil : method
            when /^250-/  then next
            when '250 OK' then break
          end
        end
        method
      end
    end

    ##
    # Returns `true` if the controller connection has been authenticated.
    #
    # @example
    #   tor.authenticated?         #=> false
    #   tor.authenticate
    #   tor.authenticated?         #=> true
    #
    # @return [Boolean]
    def authenticated?
      @authenticated || false
    end

    ##
    # Authenticates the controller connection.
    #
    # @example
    #   C: AUTHENTICATE
    #   S: 250 OK
    #
    # @example
    #   tor.authenticate
    #
    # @return [void]
    # @raise  [AuthenticationError] if authentication failed
    def authenticate(cookie = nil)
      cookie ||= @options[:cookie]
      send(:send_line, cookie ? "AUTHENTICATE #{cookie}" : "AUTHENTICATE")
      case reply = read_reply
        when '250 OK' then @authenticated = true
        else raise AuthenticationError.new(reply)
      end
      self
    end

    ##
    # Returns the version number of the Tor process.
    #
    # @example
    #   C: GETINFO version
    #   S: 250-version=0.2.1.25
    #   S: 250 OK
    #
    # @example
    #   tor.version                #=> "0.2.1.25"
    #
    # @return [String]
    def version
      send_command(:getinfo, 'version')
      reply = read_reply.split('=').last
      read_reply # skip "250 OK"
      reply
    end

    ##
    # Returns the path to the Tor configuration file.
    #
    # @example
    #   C: GETINFO config-file
    #   S: 250-config-file=/opt/local/etc/tor/torrc
    #   S: 250 OK
    #
    # @example
    #   tor.config_file            #=> #<Pathname:/opt/local/etc/tor/torrc>
    #
    # @return [Pathname]
    def config_file
      send_command(:getinfo, 'config-file')
      reply = read_reply.split('=').last
      read_reply # skip "250 OK"
      Pathname(reply)
    end

    ##
    # Returns the current (in-memory) Tor configuration.
    # Response is terminated with a "."
    #
    # @example
    #   C: GETINFO config-text
    #   S: 250+config-text=
    #   S: ControlPort 9051
    #   S: RunAsDaemon 1
    #   S: .
    def config_text
      send_command(:getinfo, 'config-text')
      reply = ""
      read_reply # skip "250+config-text="
      while line = read_reply
        break unless line != "."
        reply.concat(line + "\n")
      end
      read_reply # skip "250 OK"
      return reply
    end

    ##
    # Send a signal to the server
    #
    # @example
    # tor.signal("newnym")
    #
    # @return [String]
    def signal(name)
      send_command(:signal, name)
      read_reply
    end

  protected

    ##
    # Sends a command line over the socket.
    #
    # @param  [Symbol, #to_s] command
    # @param  [Array<String>] args
    # @return [void]
    def send_command(command, *args)
      authenticate unless authenticated?
      send_line(["#{command.to_s.upcase}", *args].join(' '))
    end

    ##
    # Sends a text line over the socket.
    #
    # @param  [String, #to_s] line
    # @return [void]
    def send_line(line)
      @socket.write(line.to_s + "\r\n")
      @socket.flush
    end

    ##
    # Reads a reply line from the socket.
    #
    # @return [String]
    def read_reply
      @socket.readline.chomp
    end

    ##
    # Used to signal an authentication error.
    #
    # @see Tor::Controller#authenticate
    class AuthenticationError < StandardError; end
  end
end
