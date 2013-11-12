$LOAD_PATH.push File.expand_path("lib")
require 'bundler_ext/version'


Gem::Specification.new do |s|
  s.name        = "bundler_ext"
  s.version     = BundlerExt::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jason Guiditta"]
  s.email       = ["jguiditt@redhat.com"]
  s.homepage    = "https://github.com/bundlerext/bundler_ext"
  s.summary     = "Load system gems via Bundler DSL"
  s.description = "Simple library leveraging the Bundler Gemfile DSL to load gems already on the system and managed by the systems package manager (like yum/apt)"
  s.license     = 'MIT'
  s.files       = Dir["lib/**/*.rb", "README.md", "MIT-LICENSE","Rakefile","CHANGELOG"]
  s.test_files  = Dir["spec/**/*.*",".rspec"]
  s.require_path = 'lib'

  s.add_dependency "bundler"
  s.requirements = ['Install the linux_admin gem and set BEXT_ACTIVATE_VERSIONS to true to activate rpm/deb installed gems']

  s.add_development_dependency('rspec', '>=1.3.0')
end
