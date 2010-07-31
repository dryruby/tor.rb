require 'ipaddr'

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

module Tor
  autoload :DNSEL,   'tor/dnsel'
  autoload :VERSION, 'tor/version'
end
