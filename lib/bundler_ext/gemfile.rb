require "bundler"

module BundlerExt
  class Gemfile
    def self.setup_env(gemfile)
      ENV['BUNDLE_GEMFILE'] = gemfile
    end

    def self.parse_env(groups)
      extra_groups = ENV['BUNDLER_EXT_GROUPS']
      extra_groups = ENV['BEXT_GROUPS'] ||
                     ENV['BUNDLER_EXT_GROUPS']
      extra_groups.split(/\s/).each {|g| groups << g.to_sym} if extra_groups
      all_groups = groups.size == 1 && groups.first == :all && !extra_groups
      {:groups       => groups.map { |g| g.to_sym},
       :extra_groups => extra_groups,
       :all_groups   => all_groups}
    end

    def self.process(bundler_gemfile, env)
      deps = {}
      bundler_gemfile.dependencies.each do |dep|
        if((env[:groups] & dep.groups).any? || env[:all_groups]) &&
          dep.current_platform?
          files = []
          Array(dep.autorequire || dep.name).each do |file|
            files << file
          end
          deps[dep.name] = {:dep => dep, :files => files}
        end
      end
      deps
    end

    def self.parse(gemfile, *groups)
      setup_env(gemfile)
      env = self.parse_env(groups)
      gemfile = Bundler::Dsl.evaluate(gemfile, nil, true)
      process(gemfile, env)
    end
  end
end
