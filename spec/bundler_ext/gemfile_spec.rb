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
        @dep = Bundler::Dependency.new 'rake', '1.0.0', 'group' => [:test]
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
        it "returns dependency autorequires" do
          dep = Bundler::Dependency.new 'rake', '1.0.0', 'require' => [:foo]
          described_class.should_receive(:dependency_in_env?).and_return(true)
          described_class.files_for_dependency(dep, {}).should == [:foo]
        end

        context "autorequires is nil" do
          it("returns depenency name") do
            dep = Bundler::Dependency.new 'rake', '1.0.0'
            described_class.should_receive(:dependency_in_env?).and_return(true)
            described_class.files_for_dependency(dep, {}).should == ['rake']
          end
        end
      end

      context "dependency not in env" do
        it "returns empty array" do
          dep = Bundler::Dependency.new 'rake', '1.0.0'
          described_class.should_receive(:dependency_in_env?).and_return(false)
          described_class.files_for_dependency(dep, {}).should == []
        end
      end
    end

    describe "#process" do
      before(:each) do
        ENV['BUNDLE_GEMFILE'] = 'spec/fixtures/Gemfile.in'
        @dep = Bundler::Dependency.new 'rake', '1.0.0'
        @gemfile = Bundler::Dsl.evaluate 'spec/fixtures/Gemfile.in', nil, true
        @gemfile.should_receive(:dependencies).and_return([@dep])
      end

      after(:each) do
        ENV.delete('BUNDLE_GEMFILE')
      end

      it "returns gemfile dependencies with files" do
        described_class.should_receive(:files_for_dependency).and_return([:files])
        described_class.process(@gemfile, {}).should ==
          {'rake' => {:dep => @dep, :files => [:files]}}
      end

      it "does not return gemfile dependencies without files" do
        described_class.should_receive(:files_for_dependency).and_return([])
        described_class.process(@gemfile, {}).should == {}
      end
    end

    describe "#parse" do
      before(:each) do
        @gemfile = 'spec/fixtures/Gemfile.in'
        ENV['BUNDLE_GEMFILE'] = @gemfile
      end

      after(:each) do
        ENV.delete('BUNDLE_GEMFILE')
      end

      it "sets up env for gemfile" do
        described_class.should_receive(:setup_env).with(@gemfile)
        described_class.parse(@gemfile)
      end

      it "retrieves env configured by gemfile" do
        described_class.should_receive(:parse_env).with([:test]).and_call_original
        described_class.parse(@gemfile, :test)
      end

      it "evaluates gemfile with bundler dsl" do
        Bundler::Dsl.should_receive(:evaluate).with(@gemfile, nil, true).and_call_original
        described_class.parse(@gemfile, :test)
      end

      it "processes gemfile / returns results" do
        env = Object.new
        gemfile = Object.new
        described_class.should_receive(:parse_env).and_return(env)
        Bundler::Dsl.should_receive(:evaluate).and_return(gemfile)
        described_class.should_receive(:process).with(gemfile, env)
        described_class.parse(@gemfile, :test)
      end
    end
  end # describe Gemfile
end # module BundlerExt
