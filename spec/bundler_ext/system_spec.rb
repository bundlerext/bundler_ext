require 'spec_helper'
require 'bundler_ext/runtime'

module BundlerExt
  describe System do
    after(:each) do
      ENV.delete('BEXT_PKG_PREFIX')
      ENV.delete('BEXT_ACTIVATE_VERSIONS')
    end

    describe "#parse_env" do
      it "sets pkg_prefix from BEXT_PKG_PREFIX env variable" do
        ENV['BEXT_PKG_PREFIX'] = 'rubygem-'
        described_class.parse_env
        expect(described_class.pkg_prefix).to eq('rubygem-')
      end

      it "defaults to blank pkg_prefix" do
        described_class.parse_env
        expect(described_class.pkg_prefix).to eq('')
      end

      it "sets activate_versions from BEXT_ACTIVATE_VERSIONS env variable" do
        ENV['BEXT_ACTIVATE_VERSIONS'] = 'true'
        described_class.parse_env
        expect(described_class.activate_versions).to eq('true')
      end
    end

    describe "#activate?" do
      context "activate_versions is false" do
        it "returns false" do
          expect(described_class.activate?).to be_nil
        end
      end

      context "not an rpm system" do
        it "returns false" do
          ENV['BEXT_ACTIVATE_VERSIONS'] = 'true'
          expect(described_class).to receive(:is_rpm_system?).and_return(false)
          expect(described_class.activate?).to be false
        end
      end

      it "returns true" do
        ENV['BEXT_ACTIVATE_VERSIONS'] = 'true'
        expect(described_class).to receive(:is_rpm_system?).and_return(true)
        expect(described_class.activate?).to be true
      end
    end

    describe "#system_name_for" do
      it "returns package name with package prefix" do
        ENV['BEXT_PKG_PREFIX'] = 'rubygem-'
        expect(described_class.system_name_for('rails')).to eq('rubygem-rails')
      end
    end

    describe "#is_rpm_system?" do
      context "/usr/bin/rpm is not an executable file" do
        it "returns false" do
          expect(File).to receive(:executable?).
               with(described_class.rpm_cmd).and_return(false)
          expect(described_class.is_rpm_system?).to be false
        end
      end

      context "/usr/bin/rpm is an executable file" do
        it "returns true" do
          expect(File).to receive(:executable?).
               with(described_class.rpm_cmd).and_return(true)
          expect(described_class.is_rpm_system?).to be true
        end
      end
    end

    describe "#rpm_cmd" do
      around(:each) do |spec|
        orpm = described_class.rpm_cmd
        spec.run
        described_class.rpm_cmd orpm
      end

      it "gets/sets rpm command" do
        described_class.rpm_cmd '/bin/rpm'
        expect(described_class.rpm_cmd).to eq('/bin/rpm')
      end

      it "defaults to /usr/bin/rpm" do
        expect(described_class.rpm_cmd).to eq('/usr/bin/rpm')
      end
    end

    describe "#system_version_for" do
      context "rpm system" do
        it "uses rpm_cmd to retrieve version" do
          expect(described_class).to receive(:is_rpm_system?).and_return(true)
          expect(described_class).to receive(:`).
            with("#{described_class.rpm_cmd} -qi rails").
            and_return("Name: rails\nVersion : 1.0.0 \nAnything")
          expect(described_class.system_version_for('rails')).to eq('1.0.0')
        end
      end

      it "returns nil" do
        expect(described_class).to receive(:is_rpm_system?).and_return(false)
        expect(described_class.system_version_for('rails')).to be_nil
      end
    end

    describe "#activate!" do
      it "activates system version of gem" do
        expect(described_class).to receive(:system_name_for).
          with('rails').and_return('rubygem-rake')
        expect(described_class).to receive(:system_version_for).
          with('rubygem-rake').and_return('1.2.3')
        expect(described_class).to receive(:gem).
          with('rails', '=1.2.3')
        described_class.activate!('rails')
      end

      it "gracefully handles load errors" do
        expect(described_class).to receive(:gem).and_raise(LoadError)
        expect { described_class.activate!('rails') }.not_to raise_error
      end

      it "gracefully handles bad requirement errors" do
        expect(described_class).to receive(:gem).
          and_raise(Gem::Requirement::BadRequirementError)
        expect { described_class.activate!('rails') }.not_to raise_error
      end
    end
  end
end
