require "bundler"

module BundlerExt
  class Gemfile
    def self.setup_env(gemfile)
      ENV['BUNDLE_GEMFILE'] = gemfile
    end

    def self.parse_env(groups)
      extra_groups = ENV['BEXT_GROUPS'] ||
                     ENV['BUNDLER_EXT_GROUPS']
      extra_groups.split(/\s/).each {|g| groups << g.to_sym} if extra_groups
      all_groups = groups.size == 1 && groups.first == :all && (!extra_groups || extra_groups.empty?)
      {:groups       => groups.map { |g| g.to_sym},
       :extra_groups => extra_groups,
       :all_groups   => all_groups}
    end

    def self.dependency_in_env?(dep, env)
      in_group = (env[:groups] & dep.groups).any? || env[:all_groups]
      in_group && dep.current_platform?
    end

    def self.files_for_dependency(dep, env)
      files = []
      if self.dependency_in_env?(dep, env)
        Array(dep.autorequire || dep.name).each do |file|
          files << file
        end
      end
      files
    end

    def self.process(bundler_gemfile, env)
      deps = {}
      bundler_gemfile.dependencies.each do |dep|
        files = self.files_for_dependency(dep, env)
        deps[dep.name] = {:dep => dep, :files => files} unless files.empty?
      end
      deps
    end

    def self.parse(gemfile, *groups)
      setup_env(gemfile)
      env = parse_env(groups)
      gemfile = Bundler::Dsl.evaluate(gemfile, nil, true)
      process(gemfile, env)
    end
  end
end
