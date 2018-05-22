# frozen_string_literal: true

# Ensure we require the local version and not one we might have installed already
require File.join([File.dirname(__FILE__), 'lib', 'fci', 'version.rb'])
Gem::Specification.new do |s|
  s.name = 'fci'
  s.version = FCI::VERSION
  s.author = 'Anton Maminov'
  s.email = 'anton.maminov@gmail.com'
  s.homepage = 'https://github.com/mamantoha/fci'
  s.platform = Gem::Platform::RUBY
  s.summary = 'Freshdesk and Crowdin integration Command Line Interface (CLI)'
  s.files = `git ls-files`.split("\n")
  s.require_paths << 'lib'
  s.bindir = 'bin'
  s.executables << 'fci'
  s.add_runtime_dependency('crowdin-api', '>=0.5.0')
  s.add_runtime_dependency('freshdesk_api', '>=0.2.0')
  s.add_runtime_dependency('gli', '>=2.13.0')
  s.add_runtime_dependency('nokogiri')
  s.add_runtime_dependency('rubyzip')
  s.add_development_dependency('rake')
  s.add_development_dependency('rdoc')
  s.add_development_dependency('rubocop')
end
