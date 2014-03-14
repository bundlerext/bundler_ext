require 'spec_helper'
require 'bundler_ext'

describe BundlerExt do
  describe "#runtime" do
    it "returns handle to runtime instance" do
      described_class.runtime.should be_an_instance_of(BundlerExt::Runtime)
      described_class.runtime.should == described_class.runtime
    end
  end

  describe "#system_require" do
    it "sets up runtime env" do
      described_class.runtime.should_receive(:setup_env)
      described_class.system_require('spec/fixtures/Gemfile.in')
    end

    it "parses specified gemfile" do
      BundlerExt::Gemfile.should_receive(:parse).
        with('spec/fixtures/Gemfile.in', *['mygroups']).
        and_call_original
      described_class.system_require('spec/fixtures/Gemfile.in', 'mygroups')
    end

    context "System.activate? is true" do
      it "activates system dependencies" do
        BundlerExt::Gemfile.should_receive(:parse).
          and_return({'rails' => {:files => []}})
        BundlerExt::System.should_receive(:activate?).and_return(true)
        BundlerExt::System.should_receive(:activate!).with('rails')
        described_class.system_require('my_gemfile')
      end
    end

    it "requires dependency files" do
      files = ['rails-includes']
      BundlerExt::Gemfile.should_receive(:parse).
        and_return({'rails' => {:files => files}})
      described_class.runtime.should_receive(:system_require).with(files)
      described_class.system_require('my_gemfile')
    end
  end

  describe "#system_setup" do
    it "sets up gemfile env" do
      BundlerExt::Gemfile.should_receive(:setup_env).
        with('spec/fixtures/Gemfile.in').at_least(:once)
      described_class.runtime.should_receive(:clear) # stub out clear
      described_class.system_setup('spec/fixtures/Gemfile.in')
    end

    it "sets runtime gemfile" do
      described_class.runtime.should_receive(:clear) # stub out clear
      described_class.system_setup('spec/fixtures/Gemfile.in')
      described_class.runtime.gemfile.to_s.should == 'spec/fixtures/Gemfile.in'
    end

    it "sets up runtime env" do
      described_class.runtime.should_receive(:clear) # stub out clear
      described_class.runtime.should_receive(:setup_env)
      described_class.system_setup('spec/fixtures/Gemfile.in')
    end

    it "clears runtime" do
      described_class.runtime.should_receive(:clear) # stub out clear
      described_class.runtime.should_receive(:setup_env)
      described_class.system_setup('spec/fixtures/Gemfile.in')
    end

    it "parses specified gemfile" do
      described_class.runtime.should_receive(:clear) # stub out clear
      BundlerExt::Gemfile.should_receive(:parse).
        with('spec/fixtures/Gemfile.in', *['mygroups']).
        and_call_original
      described_class.system_setup('spec/fixtures/Gemfile.in', 'mygroups')
    end

    context "System.activate? is true" do
      it "activates system dependencies" do
        described_class.runtime.should_receive(:clear) # stub out clear
        BundlerExt::Gemfile.should_receive(:parse).
          and_return({'rails' => {:dep => ::Gem::Dependency.new('rails')}})
        BundlerExt::System.should_receive(:activate?).and_return(true)
        BundlerExt::System.should_receive(:activate!).with('rails')
        described_class.system_setup('spec/fixtures/Gemfile.in')
      end
    end

    it "adds dependency specs to runtime" do
      dep = ::Gem::Dependency.new('rails')
      described_class.runtime.should_receive(:clear) # stub out clear
      BundlerExt::Gemfile.should_receive(:parse).
        and_return({'rails' => {:dep => dep}})
      described_class.runtime.should_receive(:add_spec).with(dep.to_spec())
      described_class.system_setup('spec/fixtures/Gemfile.in')
    end
  end
end
