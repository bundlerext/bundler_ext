require 'spec_helper'
require 'bundler_ext/gemfile'

module BundlerExt
  describe Gemfile do
    describe "#setup_env" do
      around(:each) do |spec|
        orig = ENV['BUNDLE_GEMFILE']
        spec.run
        ENV['BUNDLE_GEMFILE'] = orig
      end

      it "sets BUNDLE_GEMFILE env varialbe" do
        described_class.setup_env('Gemfile.custom')
        ENV['BUNDLE_GEMFILE'].should == 'Gemfile.custom'
      end
    end

    describe "#parse_env" do
      around(:each) do |spec|
        beg1 = ENV['BUNDLER_EXT_GROUPS']
        beg2 = ENV['BEXT_GROUPS']
        spec.run
        ENV['BUNDLER_EXT_GROUPS'] = beg1
        ENV['BEXT_GROUPS']       = beg2
      end

      it "converts specified groups to symbols" do
        described_class.parse_env(['development', 'test'])[:groups].should == [:development, :test]
      end

      it "retrieves extra groups from BUNDLER_EXT_GROUPS env variable" do
        ENV['BUNDLER_EXT_GROUPS'] = 'development test'
        env = described_class.parse_env([])
        env[:groups].should == [:development, :test]
        env[:extra_groups].should == 'development test'
      end

      it "retrieves extra groups from BEXT_GROUPS env variable" do
        ENV['BEXT_GROUPS'] = 'development test'
        env = described_class.parse_env([])
        env[:groups].should == [:development, :test]
        env[:extra_groups].should == 'development test'
      end

      context "groups == [:all] and no extra groups specified" do
        it "sets all_groups true" do
          described_class.parse_env([:all])[:all_groups].should be_true
        end
      end

      context "groups != [:all]" do
        it "sets all_groups false" do
          described_class.parse_env([:dev])[:all_groups].should be_false
        end
      end

      context "extra groups specified" do
        it "sets all_groups false" do
          ENV['BEXT_GROUPS'] = 'development'
          described_class.parse_env([:all])[:all_groups].should be_false
        end
      end
    end

    describe "#dependency_in_env?" do
      before(:each) do
        @dep = Bundler::Dependency.new 'rake', '1.0.0', :groups => [:test]
        @env = {:groups => []}
      end

      context "dep.current_platform? is false" do
        it "returns false" do
          @env[:all_groups] = true
          @dep.should_receive(:current_platform?).and_return(false)
          described_class.dependency_in_env?(@dep, @env).should be_false
        end
      end

      context ":all_groups is false and depenency _not_ in env groups" do
        it "returns false" do
          @env[:all_groups] = false
          @env[:groups] << :dev
          described_class.dependency_in_env?(@dep, @env).should be_false
        end
      end

      context ":all_groups and dep.current_platform? are true" do
        it "returns true" do
          @env[:all_groups] = true
          @dep.should_receive(:current_platform?).and_return(true)
          described_class.dependency_in_env?(@dep, @env).should be_true
        end
      end

      context "dep is in a group and dep.current_platform? is true" do
        it "returns true" do
          @env[:groups] << :dev
          @dep.groups   << :dev
          @dep.should_receive(:current_platform?).and_return(true)
          described_class.dependency_in_env?(@dep, @env).should be_true
        end
      end
    end

    describe "#files_for_dependency" do
      context "dependency in env" do
        it("returns dependency autorequires")
        context "autorequires is nil" do
          it("returns depenency name")
        end
      end

      context "dependency not in env" do
        it "returns empty array"
      end
    end

    describe "#process" do
      it "returns gemfile dependencies with files"
      it "does not return gemfile dependencies without files"
    end

    describe "#parse" do
      it "sets up env for gemfile"
      it "retrieves env configured by gemfile"
      it "evaluates gemfile with bundler dsl"
      it "processes gemfile / returns results"
    end
  end # describe Gemfile
end # module BundlerExt
