require 'rubygems/requirement'

# ruby compat fix
Gem::Requirement::BadRequirementError = ArgumentError if RUBY_VERSION < '2'

module BundlerExt
  class System
    def self.parse_env
      @pkg_prefix = ENV['BEXT_PKG_PREFIX'] || ''
      @activate_versions = ENV['BEXT_ACTIVATE_VERSIONS']
    end

    def self.activate?
      parse_env
      return @activate_enabled = false unless @activate_versions

      begin
        require "linux_admin"
      rescue LoadError
        puts "linux_admin not installed, cannot retrieve versions to activate"
        return @activate_enabled = false
      end

      @activate_enabled = true
    end

    def self.system_name_for(name)
      parse_env
      "#{@pkg_prefix}#{name}"
    end

    def self.system_version_for(name)
      # TODO replace this w/ direct call to rpm/deb
      LinuxAdmin::Package.info(name)['version']
    end

    def self.activate!(name)
      begin
        sys_name = system_name_for(name)
        version  = system_version_for(sys_name)
        gem name, "=#{version}"
      rescue LoadError, Gem::Requirement::BadRequirementError
      end
    end
  end
end
