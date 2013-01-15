$LOAD_PATH.push File.expand_path("lib")
require 'bundler_ext/version'


Gem::Specification.new do |s|
  s.name        = "bundler_ext"
  s.version     = BundlerExt::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jason Guiditta"]
  s.email       = ["aeolus-devel@lists.fedorahosted.org, jguiditt@redhat.com"]
  s.homepage    = "https://github.com/aeolus-incubator/bundler_ext"
  s.summary     = "Load system gems via Bundler DSL"
  s.description = "Simple library leveraging the Bundler Gemfile DSL to load gems already on the system and managed by the systems package manager (like yum/apt)"
  s.license     = 'MIT'
  s.files       = Dir["lib/**/*.rb", "README.md", "MIT-LICENSE","Rakefile","CHANGELOG"]
  s.test_files  = Dir["spec/**/*.*",".rspec"]
  s.require_path = 'lib'

  s.add_dependency "bundler"

  s.add_development_dependency('rspec', '>=1.3.0')
end
