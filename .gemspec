#!/usr/bin/env ruby -rubygems
# -*- encoding: utf-8 -*-

GEMSPEC = Gem::Specification.new do |gem|
  gem.version            = File.read('VERSION').chomp
  gem.date               = File.mtime('VERSION').strftime('%Y-%m-%d')

  gem.name               = 'tor'
  gem.homepage           = 'http://cypherpunk.rubyforge.org/tor/'
  gem.license            = 'Public Domain' if gem.respond_to?(:license=)
  gem.summary            = 'Onion routing for Ruby.'
  gem.description        = 'Tor.rb is a Ruby library for interacting with the Tor anonymity network.'
  gem.rubyforge_project  = 'cypherpunk'

  gem.author             = 'Arto Bendiken'
  gem.email              = 'or-talk@seul.org' # @see http://archives.seul.org/or/talk/

  gem.platform           = Gem::Platform::RUBY
  gem.files              = %w(AUTHORS CONTRIBUTORS README UNLICENSE VERSION) + Dir.glob('lib/**/*.rb')
  gem.bindir             = %q(bin)
  gem.executables        = %w()
  gem.default_executable = gem.executables.first
  gem.require_paths      = %w(lib)
  gem.extensions         = %w()
  gem.test_files         = %w()
  gem.has_rdoc           = false

  gem.required_ruby_version      = '>= 1.8.1'
  gem.requirements               = ['Tor (>= 0.2.1.25)']
  gem.add_development_dependency 'yard',  '>= 0.5.8'
  gem.add_development_dependency 'rspec', '>= 1.3.0'
  gem.post_install_message       = nil
end
