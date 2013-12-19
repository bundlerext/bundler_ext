require 'pathname'
require 'bundler_ext/runtime'
require 'bundler_ext/gemfile'
require 'bundler_ext/system'

module BundlerExt
  def self.runtime
    @runtime ||= BundlerExt::Runtime.new
  end

  def self.system_require(gemfile, *groups)
    runtime.setup_env

    Gemfile.parse(gemfile, *groups).each do |name, gem_dep|
      if System.activate?
        System.activate!(name)
      end

      runtime.system_require(gem_dep[:files])
    end
  end

  def self.system_setup(gemfile, *groups)
    Gemfile.setup_env(gemfile)
    runtime.gemfile(Pathname.new(gemfile))
    runtime.setup_env
    runtime.clear
    Gemfile.parse(gemfile, *groups).each do |name, gem_dep|
      if System.activate?
        System.activate!(name)
      end

      runtime.add_spec(gem_dep[:dep].to_spec())
    end
  end
end
