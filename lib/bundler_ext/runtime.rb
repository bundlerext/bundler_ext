require "bundler_ext/output"

module BundlerExt
  class Runtime
    def gemfile(new_val = nil)
      @bext_gemfile ||= Bundler.default_gemfile
      @bext_gemfile   = new_val unless new_val.nil?
      @bext_gemfile
    end

    def root
      gemfile.dirname.expand_path
    end

    def bundler
      @bundler_runtime ||= Bundler::Runtime.new(root, gemfile)
    end

    def rubygems
      @bundler_rubygems ||= Bundler::RubygemsIntegration.new
    end


    def setup_env
      # some rubygems do not play well with daemonized processes ($HOME is empty)
      ENV['HOME'] = ENV['BEXT_HOME']        if ENV['BEXT_HOME']
      ENV['HOME'] = ENV['BUNDLER_EXT_HOME'] if ENV['BUNDLER_EXT_HOME']
    end

    # Helper to generate, taken from bundler_ext
    def self.namespaced_file(file)
      return nil unless file.to_s.include?('-')
      file.respond_to?(:name) ? file.name.gsub('-', '/') : file.to_s.gsub('-', '/')
    end

    def system_require(files)
      files.each do |dep|
        # this part also take from lib/bundler/runtime.rb (github/master)
        begin
          #puts "Attempting to require #{dep}"
          require dep
        rescue LoadError => e
          namespaced_file = self.class.namespaced_file(dep)
          begin
            require namespaced_file unless namespaced_file.nil?
          rescue LoadError => e2
            e = e2
          end

          Output.strict_err "Gem loading error: #{e.message}"
        end
      end
    end

    def clear
      bundler.send :clean_load_path
    end

    def add_spec(spec)
      # copied from Bundler::Runtime#setup
      rubygems.mark_loaded spec
      load_paths = spec.load_paths.reject {|path| $LOAD_PATH.include?(path)}
      $LOAD_PATH.unshift(*load_paths)
    end
  end
end
