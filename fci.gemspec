# Ensure we require the local version and not one we might have installed already
require File.join([File.dirname(__FILE__),'lib','fci','version.rb'])
spec = Gem::Specification.new do |s|
  s.name = 'fci'
  s.version = Fci::VERSION
  s.author = 'Your Name Here'
  s.email = 'your@email.address.com'
  s.homepage = 'http://your.website.com'
  s.platform = Gem::Platform::RUBY
  s.summary = 'A description of your project'
  s.files = `git ls-files`.split("
")
  s.require_paths << 'lib'
  s.has_rdoc = true
  s.extra_rdoc_files = ['README.rdoc','fci.rdoc']
  s.rdoc_options << '--title' << 'fci' << '--main' << 'README.rdoc' << '-ri'
  s.bindir = 'bin'
  s.executables << 'fci'
  s.add_runtime_dependency('crowdin-api')
  s.add_runtime_dependency('freshdesk_api')
  s.add_development_dependency('rake')
  s.add_development_dependency('rdoc')
  s.add_development_dependency('aruba')
  s.add_runtime_dependency('gli','2.13.0')
end
