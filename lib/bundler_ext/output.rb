module BundlerExt
  class Output
    def self.parse_env
      @nostrict = ENV['BEXT_NOSTRICT'] || ENV['BUNDLER_EXT_NOSTRICT']
      @verbose = ENV['BEXT_VERBOSE'] || ENV['BUNDLER_EXT_VERBOSE']
    end

    def self.strict_err(msg)
      parse_env
      if @nostrict
        puts msg
      else
        raise msg
      end
    end

    def self.verbose_msg(msg)
      puts msg if @verbose
    end
  end
end
