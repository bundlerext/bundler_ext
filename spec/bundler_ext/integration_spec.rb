require 'spec_helper'

# skip system specs unless we can load linux_admin
skip_system = false
begin
  require 'linux_admin'
rescue LoadError
  skip_system = true
end

  describe BundlerExt do
    before(:each) do
      @gemfile = 'spec/fixtures/Gemfile.in'
    end
    after(:each) do
      ENV['BUNDLER_PKG_PREFIX'] = nil
      ENV['BEXT_ACTIVATE_VERSIONS'] = nil
      ENV['BEXT_PKG_PREFIX'] = nil
      ENV['BEXT_NOSTRICT'] = nil
      ENV['BEXT_GROUPS'] = nil
    end

    describe "#parse_from_gemfile" do
      describe "with no group passed in" do
        it "should return nothing to require" do
          libs = BundlerExt::Gemfile.parse(@gemfile)
          expect(libs).to be_an(Hash)
          expect(libs.keys).to_not include('deltacloud-client')
          expect(libs.keys).to_not include('vcr')
        end
      end
      describe "with :all passed in" do
        it "should return the list of system libraries in all groups to require" do
          libs = BundlerExt::Gemfile.parse(@gemfile, :all)
          expect(libs).to be_an(Hash)
          expect(libs.keys).to include('deltacloud-client')
          expect(libs['deltacloud-client'][:files]).to eq(['deltacloud'])
          expect(libs.keys).to include('vcr')
        end
      end
      describe "with group passed in" do
        it "should not return any deps that are not in the 'development' group" do
          libs = BundlerExt::Gemfile.parse(@gemfile,'development')
          expect(libs).to be_an(Hash)
          expect(libs.keys).to_not include('deltacloud-client')
        end
        it "should return only deps that are in the :test group" do
          libs = BundlerExt::Gemfile.parse(@gemfile, :test)
          expect(libs).to be_an(Hash)
          expect(libs.keys).to_not include('deltacloud-client')
          expect(libs.keys).to include('vcr')
        end
        it "should return deps from both the :default and :test groups" do
          libs = BundlerExt::Gemfile.parse(@gemfile, :default, :test)
          expect(libs).to be_an(Hash)
          expect(libs.keys).to include('deltacloud-client')
          expect(libs.keys).to include('vcr')
        end
      end
      it "should only return deps for the current platform" do
        libs = BundlerExt::Gemfile.parse(@gemfile)
        expect(libs).to be_an(Hash)
        if RUBY_VERSION < "1.9"
          expect(libs.keys).to_not include('cinch')
        else
          expect(libs.keys).to_not include('fastercsv')
        end
      end
    end
    describe "#system_require" do
      it "strict mode should fail loading non existing gem" do
        expect { BundlerExt.system_require(@gemfile, :fail) }.to raise_error
      end

      it "non-strict mode should load the libraries in the gemfile" do
        ENV['BEXT_NOSTRICT'] = 'true'
        BundlerExt.system_require(@gemfile)
        expect(defined?(Gem)).to be_truthy
      end

      it "non-strict mode should load the libraries in the gemfile" do
        ENV['BUNDLER_EXT_NOSTRICT'] = 'true'
        BundlerExt.system_require(@gemfile)
        expect(defined?(Gem)).to be_truthy
      end

      it "non-strict mode should load the libraries in the gemfile" do
        ENV['BEXT_NOSTRICT'] = 'true'
        BundlerExt.system_require(@gemfile, :fail)
        expect(defined?(Gem)).to be_truthy
      end

      it "non-strict mode should load the libraries in the gemfile" do
        ENV['BUNDLER_EXT_NOSTRICT'] = 'true'
        BundlerExt.system_require(@gemfile, :fail)
        expect(defined?(Gem)).to be_truthy
      end
      it "non-strict mode should load the libraries using env var list" do
        ENV['BEXT_GROUPS'] = 'test development blah'
        ENV['BEXT_NOSTRICT'] = 'true'
        BundlerExt.system_require(@gemfile)
        expect(defined?(Gem)).to be_truthy
      end

      it "non-strict mode should load the libraries using env var list" do
        ENV['BUNLDER_EXT_GROUPS'] = 'test development blah'
        ENV['BEXT_NOSTRICT'] = 'true'
        BundlerExt.system_require(@gemfile)
        expect(defined?(Gem)).to be_truthy
      end

      unless skip_system
        context "ENV['BEXT_ACTIVATE_VERSIONS'] is true" do
          before(:each) do
            ENV['BUNDLER_EXT_NOSTRICT'] = 'true'
            ENV['BEXT_ACTIVATE_VERSIONS'] = 'true'
          end

          it "activates the version of the system installed package" do
            gems = BundlerExt::Gemfile.parse(@gemfile, :all)
            gems.each { |gem,gdep|
              version = rand(100)
              expect(BundlerExt::System).to receive(:system_name_for).with(gem).
                         and_return(gem)
              expect(BundlerExt::System).to receive(:system_version_for).with(gem).
                         and_return(version)
              expect(BundlerExt::System).to receive(:gem).with(gem, "=#{version}")
            }
            BundlerExt.system_require(@gemfile, :all)
          end

          context "ENV['BEXT_PKG_PREFIX'] is specified" do
            it "prepends bundler pkg prefix onto system package name to load" do
              ENV['BEXT_PKG_PREFIX'] = 'rubygem-'
              gems = BundlerExt::Gemfile.parse(@gemfile, :all)
              gems.each { |gem,gdep|
                expect(BundlerExt::System).to receive(:system_version_for).with("rubygem-#{gem}").
                           and_return('0')
              }
              BundlerExt.system_require(@gemfile, :all)
            end
          end
        end
      end
    end
  end
