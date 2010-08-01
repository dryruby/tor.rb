Tor.rb: Onion Routing for Ruby
==============================

This is a Ruby library for interacting with the [Tor][] anonymity network.

* <http://github.com/bendiken/tor-ruby>

Features
--------

* Supports checking whether Tor is installed in the user's current `PATH`,
  and if it is, returning the version number.
* Supports querying the [Tor DNS Exit List (DNSEL)][TorDNSEL] to determine
  whether a particular host is a Tor exit node or not.

Examples
--------

    require 'rubygems'
    require 'tor'

### Checking whether Tor is installed and which version it is

    Tor.available?                                     #=> true
    Tor.version                                        #=> "0.2.1.25"

### Checking whether a particular host is a Tor exit node

    Tor::DNSEL.include?("208.75.57.100")               #=> true
    Tor::DNSEL.include?("1.2.3.4")                     #=> false

Documentation
-------------

* <http://cypherpunk.rubyforge.org/tor/>

Dependencies
------------

* [Ruby](http://ruby-lang.org/) (>= 1.8.7) or (>= 1.8.1 with [Backports][])

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
[OR]:        http://en.wikipedia.org/wiki/Onion_routing
[Backports]: http://rubygems.org/gems/backports
