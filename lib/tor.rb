require 'pathname'

if RUBY_VERSION < '1.8.7'
  # @see http://rubygems.org/gems/backports
  begin
    require 'backports/1.8.7'
  rescue LoadError
    begin
      require 'rubygems'
      require 'backports/1.8.7'
    rescue LoadError
      abort "Tor.rb requires Ruby 1.8.7 or the Backports gem (hint: `gem install backports')."
    end
  end
end

##
# @see https://www.torproject.org/
module Tor
  require_relative 'tor/config'
  require_relative 'tor/control'
  require_relative 'tor/dnsel'
  require_relative 'tor/version'

  ##
  # Returns `true` if the Tor process is running locally, `false` otherwise.
  #
  # This works by attempting to establish a Tor Control Protocol (TC)
  # connection to the standard control port 9051 on `localhost`. If Tor
  # hasn't been configured with the `ControlPort 9051` option, this will
  # return `false`.
  #
  # @example
  #   Tor.running?      #=> false
  #
  # @return [Boolean]
  # @since  0.1.2
  def self.running?
    begin
      Tor::Controller.new.quit
      true
    rescue Errno::ECONNREFUSED
      false
    end
  end

  ##
  # Returns `true` if Tor is available, `false` otherwise.
  #
  # @example
  #   Tor.available?    #=> true
  #
  # @return [Boolean]
  def self.available?
    !!program_path
  end

  ##
  # Returns the Tor version number, or `nil` if Tor is not available.
  #
  # @example
  #   Tor.version       #=> "0.2.1.25"
  #
  # @return [String]
  def self.version
    if available? && `#{program_path} --version` =~ /Tor v(\d+)\.(\d+)\.(\d+)\.(\d+)/
      [$1, $2, $3, $4].join('.')
    elsif available? && `#{program_path} --version` =~ /Tor version (\d+)\.(\d+)\.(\d+)\.(\d+)/
      [$1, $2, $3, $4].join('.')
    end
  end

  ##
  # Returns the path to the `tor` executable, or `nil` if the program could
  # not be found in the user's current `PATH` environment.
  #
  # @example
  #   Tor.program_path  #=> "/opt/local/bin/tor"
  #
  # @param  [String, #to_s] program_name
  # @return [String]
  def self.program_path(program_name = :tor)
    ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
      program_path = File.join(path, program_name.to_s)
      return program_path if File.executable?(program_path)
    end
    return nil
  end
end
