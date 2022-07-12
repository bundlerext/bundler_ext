require 'spec_helper'
require 'bundler_ext'

describe BundlerExt do
  describe "#runtime" do
    it "returns handle to runtime instance" do
      expect(described_class.runtime).to be_an_instance_of(BundlerExt::Runtime)
      expect(described_class.runtime).to eq(described_class.runtime)
    end
  end

  describe "#system_require" do
    it "sets up runtime env" do
      expect(described_class.runtime).to receive(:setup_env)
      described_class.system_require('spec/fixtures/Gemfile.in')
    end

    it "parses specified gemfile" do
      expect(BundlerExt::Gemfile).to receive(:parse).
        with('spec/fixtures/Gemfile.in', *['mygroups']).
        and_call_original
      described_class.system_require('spec/fixtures/Gemfile.in', 'mygroups')
    end

    context "System.activate? is true" do
      it "activates system dependencies" do
        expect(BundlerExt::Gemfile).to receive(:parse).
          and_return({'rails' => {:files => []}})
        expect(BundlerExt::System).to receive(:activate?).and_return(true)
        expect(BundlerExt::System).to receive(:activate!).with('rails')
        described_class.system_require('my_gemfile')
      end
    end

    it "requires dependency files" do
      files = ['rails-includes']
      expect(BundlerExt::Gemfile).to receive(:parse).
        and_return({'rails' => {:files => files}})
      expect(described_class.runtime).to receive(:system_require).with(files)
      described_class.system_require('my_gemfile')
    end
  end

  describe "#system_setup" do
    it "sets up gemfile env" do
      expect(BundlerExt::Gemfile).to receive(:setup_env).
        with('spec/fixtures/Gemfile.in').at_least(:once)
      expect(described_class.runtime).to receive(:clear) # stub out clear
      described_class.system_setup('spec/fixtures/Gemfile.in')
    end

    it "sets runtime gemfile" do
      expect(described_class.runtime).to receive(:clear) # stub out clear
      described_class.system_setup('spec/fixtures/Gemfile.in')
      expect(described_class.runtime.gemfile.to_s).to eq('spec/fixtures/Gemfile.in')
    end

    it "sets up runtime env" do
      expect(described_class.runtime).to receive(:clear) # stub out clear
      expect(described_class.runtime).to receive(:setup_env)
      described_class.system_setup('spec/fixtures/Gemfile.in')
    end

    it "clears runtime" do
      expect(described_class.runtime).to receive(:clear) # stub out clear
      expect(described_class.runtime).to receive(:setup_env)
      described_class.system_setup('spec/fixtures/Gemfile.in')
    end

    it "parses specified gemfile" do
      expect(described_class.runtime).to receive(:clear) # stub out clear
      expect(BundlerExt::Gemfile).to receive(:parse).
        with('spec/fixtures/Gemfile.in', *['mygroups']).
        and_call_original
      described_class.system_setup('spec/fixtures/Gemfile.in', 'mygroups')
    end

    context "System.activate? is true" do
      it "activates system dependencies" do
        expect(described_class.runtime).to receive(:clear) # stub out clear
        expect(BundlerExt::Gemfile).to receive(:parse).
          and_return({'rails' => {:dep => ::Gem::Dependency.new('rails')}})
        expect(BundlerExt::System).to receive(:activate?).and_return(true)
        expect(BundlerExt::System).to receive(:activate!).with('rails')
        described_class.system_setup('spec/fixtures/Gemfile.in')
      end
    end

    it "adds dependency specs to runtime" do
      dep = ::Gem::Dependency.new('rails')
      expect(described_class.runtime).to receive(:clear) # stub out clear
      expect(BundlerExt::Gemfile).to receive(:parse).
        and_return({'rails' => {:dep => dep}})
      expect(described_class.runtime).to receive(:add_spec).with(dep.to_spec())
      described_class.system_setup('spec/fixtures/Gemfile.in')
    end
  end
end
