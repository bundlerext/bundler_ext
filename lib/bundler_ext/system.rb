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
      return @activate_enabled = false unless @activate_versions &&
                                              File.exists?(rpm_cmd)
      @activate_enabled = true
    end

    def self.system_name_for(name)
      parse_env
      "#{@pkg_prefix}#{name}"
    end

    def self.is_rpm_system?
      File.executable?('/usr/bin/rpm')
    end

    def self.rpm_cmd(new_val=nil)
      @rpm_cmd ||= '/usr/bin/rpm'
      @rpm_cmd   = new_val unless new_val.nil?
      @rpm_cmd
    end

    def self.system_version_for(name)
      if is_rpm_system?
        out = `#{rpm_cmd} -qi #{name}`
        version = out =~ /.*Version\s*:\s*([^\s]*)\s+.*/ ?
          $1 : nil
      else
        # TODO support debian, other platforms
        version = nil
      end

      version
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
