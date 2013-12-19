module BundlerExt
  class Output
    def self.parse_env
      @nostrict = ENV['BEXT_NOSTRICT'] || ENV['BUNDLER_EXT_NOSTRICT']
    end

    def self.strict_err(msg)
      parse_env
      if @nostrict
        puts msg
      else
        raise msg
      end
    end
  end
end
