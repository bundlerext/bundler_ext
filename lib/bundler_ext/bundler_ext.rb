require "bundler"

# some rubygems does not play well with daemonized processes ($HOME is empty)
ENV['HOME'] = ENV['BUNDLER_EXT_HOME'] if ENV['BUNDLER_EXT_HOME']

class BundlerExt
  def self.parse_from_gemfile(gemfile,*groups)
    ENV['BUNDLE_GEMFILE'] = gemfile
    extra_groups = ENV['BUNDLER_EXT_GROUPS']
    extra_groups.split(/\s/).each {|g| groups << g.to_sym} if extra_groups
    all_groups = false
    all_groups = true if groups.size == 1 and groups.include?(:all) and not extra_groups
    groups.map! { |g| g.to_sym }
    g = Bundler::Dsl.evaluate(gemfile,'foo',true)
    list = []
    g.dependencies.each do |dep|
      if ((groups & dep.groups).any? || all_groups) && dep.current_platform?
        Array(dep.autorequire || dep.name).each do |file|
          list << file
        end
      end
    end
    list
  end

  def self.strict_error(msg)
    if ENV['BUNDLER_EXT_NOSTRICT']
      puts msg
    else
      raise msg
    end
  end

  def self.system_require(gemfile,*groups)
    BundlerExt.parse_from_gemfile(gemfile,*groups).each do |dep|
      #This part ripped wholesale from lib/bundler/runtime.rb (github/master)
      begin
        #puts "Attempting to require #{dep}"
        require dep
      rescue LoadError => e
        #puts "Caught error: #{e.message}"
        if dep.include?('-')
          begin
            if dep.respond_to? :name
              namespaced_file = dep.name.gsub('-', '/')
            else
              # try to load unresolved deps
              namespaced_file = dep.gsub('-', '/')
            end
            #puts "Munged the name, now trying to require as #{namespaced_file}"
            require namespaced_file
          rescue LoadError => e2
            strict_error "Gem loading error: #{e2.message}"
          end
        else
          strict_error "Gem loading error: #{e.message}"
        end
      end
    end
  end

  def self.output
    ENV['BUNDLER_STDERR'] || $stderr
  end
end
