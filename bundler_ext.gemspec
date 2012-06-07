Gem::Specification.new do |s|
  s.name        = "bundler_ext"
  s.version     = "0.1.0"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jason Guiditta"]
  s.email       = ["aeolus-devel@lists.fedorahosted.org, jguiditt@redhat.com"]
  s.homepage    = "https://github.com/aeolus-incubator/bundler_ext"
  s.summary     = "Load system gems via Bundler DSL"
  s.description = "Simple library leveraging the Bundler Gemfile DSL to load gems already on the system and managed by the systems package manager (like yum/apt)"
  s.license = 'ASL 2.0'
  s.files        = Dir["{lib,spec}/**/*.rb", "*.md"]
  s.require_path = 'lib'

  s.add_dependency "bundler"

  s.add_development_dependency('rspec', '~>1.3.0')
end
