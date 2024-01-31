Tor.rb: Onion Routing for Ruby
==============================

This is a Ruby library for interacting with the [Tor][] anonymity network.

* <http://github.com/bendiken/tor-ruby>

Features
--------

* Supports checking whether Tor is installed in the user's current `PATH`,
  and if it is, returning the version number.
* Supports parsing Tor configuration files and looking up the values of
  particular options.
* Supports querying and controlling a locally-running Tor process using the
  [Tor Control Protocol (TC)][TC] over a socket connection.
* Supports querying the [Tor DNS Exit List (DNSEL)][TorDNSEL] to determine
  whether a particular host is a Tor exit node or not.
* Compatible with Ruby 1.8.7+, Ruby 1.9.x, and JRuby 1.4/1.5.

Examples
--------

    require 'rubygems'
    require 'tor'

### Checking whether Tor is installed and which version it is

    Tor.available?                                     #=> true
    Tor.version                                        #=> "0.2.1.25"

### Parsing the Tor configuration file (1)

    torrc = Tor::Config.load("/etc/tor/torrc")

### Parsing the Tor configuration file (2)

    Tor::Config.open("/etc/tor/torrc") do |torrc|
      puts "Tor SOCKS port: #{torrc['SOCKSPort']}"
      puts "Tor control port: #{torrc['ControlPort']}"
      puts "Tor exit policy:"
      torrc.each('ExitPolicy') do |key, value|
        puts "  #{value}"
      end
    end

### Communicating with a running Tor process

    Tor::Controller.connect(:port => 9051) do |tor|
      puts "Tor version: #{tor.version}"
      puts "Tor config file: #{tor.config_file}"
    end

### Checking whether a particular host is a Tor exit node

    Tor::DNSEL.include?("185.220.101.21")               #=> true
    Tor::DNSEL.include?("1.2.3.4")                     #=> false

Dependencies
------------

* [Ruby](http://ruby-lang.org/) (>= 1.8.7) or (>= 1.8.1 with [Backports][])
* [Tor](https://www.torproject.org/download.html.en) (>= 0.2.1)

Installation
------------

The recommended installation method is via [RubyGems](http://rubygems.org/).
To install the latest official release of Tor.rb, do:

    % [sudo] gem install tor                 # Ruby 1.8.7+ or 1.9.x
    % [sudo] gem install backports tor       # Ruby 1.8.1+

Download
--------

To get a local working copy of the development repository, do:

    % git clone git://github.com/bendiken/tor-ruby.git

Alternatively, you can download the latest development version as a tarball
as follows:

    % wget http://github.com/bendiken/tor-ruby/tarball/master

Author
------

* [Arto Bendiken](mailto:arto.bendiken@gmail.com) - <http://ar.to/>

License
-------

Tor.rb is free and unencumbered public domain software. For more
information, see <http://unlicense.org/> or the accompanying UNLICENSE file.

[Tor]:       https://www.torproject.org/
[TorDNSEL]:  https://www.torproject.org/tordnsel/
[TC]:        http://gitweb.torproject.org/tor.git?a=blob_plain;hb=HEAD;f=doc/spec/control-spec.txt
[OR]:        http://en.wikipedia.org/wiki/Onion_routing
[Backports]: http://rubygems.org/gems/backports
