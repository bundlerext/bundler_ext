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
        expect(ENV['BUNDLE_GEMFILE']).to eq('Gemfile.custom')
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
        expect(described_class.parse_env(['development', 'test'])[:groups]).to eq([:development, :test])
      end

      it "retrieves extra groups from BUNDLER_EXT_GROUPS env variable" do
        ENV['BUNDLER_EXT_GROUPS'] = 'development test'
        env = described_class.parse_env([])
        expect(env[:groups]).to eq([:development, :test])
        expect(env[:extra_groups]).to eq('development test')
      end

      it "retrieves extra groups from BEXT_GROUPS env variable" do
        ENV['BEXT_GROUPS'] = 'development test'
        env = described_class.parse_env([])
        expect(env[:groups]).to eq([:development, :test])
        expect(env[:extra_groups]).to eq('development test')
      end

      context "groups == [:all] and no extra groups specified" do
        it "sets all_groups true" do
          expect(described_class.parse_env([:all])[:all_groups]).to be true
        end
      end

      context "groups != [:all]" do
        it "sets all_groups false" do
          expect(described_class.parse_env([:dev])[:all_groups]).to be false
        end
      end

      context "extra groups specified" do
        it "sets all_groups false" do
          ENV['BEXT_GROUPS'] = 'development'
          expect(described_class.parse_env([:all])[:all_groups]).to be false
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
          expect(@dep).to receive(:current_platform?).and_return(false)
          expect(described_class.dependency_in_env?(@dep, @env)).to be false
        end
      end

      context ":all_groups is false and depenency _not_ in env groups" do
        it "returns false" do
          @env[:all_groups] = false
          @env[:groups] << :dev
          expect(described_class.dependency_in_env?(@dep, @env)).to be false
        end
      end

      context ":all_groups and dep.current_platform? are true" do
        it "returns true" do
          @env[:all_groups] = true
          expect(@dep).to receive(:current_platform?).and_return(true)
          expect(described_class.dependency_in_env?(@dep, @env)).to be true
        end
      end

      context "dep is in a group and dep.current_platform? is true" do
        it "returns true" do
          @env[:groups] << :dev
          @dep.groups   << :dev
          expect(@dep).to receive(:current_platform?).and_return(true)
          expect(described_class.dependency_in_env?(@dep, @env)).to be true
        end
      end
    end

    describe "#files_for_dependency" do
      context "dependency in env" do
        it "returns dependency autorequires" do
          dep = Bundler::Dependency.new 'rake', '1.0.0', 'require' => [:foo]
          expect(described_class).to receive(:dependency_in_env?).and_return(true)
          expect(described_class.files_for_dependency(dep, {})).to eq([:foo])
        end

        context "autorequires is nil" do
          it("returns depenency name") do
            dep = Bundler::Dependency.new 'rake', '1.0.0'
            expect(described_class).to receive(:dependency_in_env?).and_return(true)
            expect(described_class.files_for_dependency(dep, {})).to eq(['rake'])
          end
        end
      end

      context "dependency not in env" do
        it "returns empty array" do
          dep = Bundler::Dependency.new 'rake', '1.0.0'
          expect(described_class).to receive(:dependency_in_env?).and_return(false)
          expect(described_class.files_for_dependency(dep, {})).to eq([])
        end
      end
    end

    describe "#process" do
      before(:each) do
        ENV['BUNDLE_GEMFILE'] = 'spec/fixtures/Gemfile.in'
        @dep = Bundler::Dependency.new 'rake', '1.0.0'
        @gemfile = Bundler::Dsl.evaluate 'spec/fixtures/Gemfile.in', nil, true
        expect(@gemfile).to receive(:dependencies).and_return([@dep])
      end

      after(:each) do
        ENV.delete('BUNDLE_GEMFILE')
      end

      it "returns gemfile dependencies with files" do
        expect(described_class).to receive(:files_for_dependency).and_return([:files])
        expect(described_class.process(@gemfile, {})).to eq({'rake' => {:dep => @dep, :files => [:files]}})
      end

      it "does not return gemfile dependencies without files" do
        expect(described_class).to receive(:files_for_dependency).and_return([])
        expect(described_class.process(@gemfile, {})).to eq({})
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
        expect(described_class).to receive(:setup_env).with(@gemfile)
        described_class.parse(@gemfile)
      end

      it "retrieves env configured by gemfile" do
        expect(described_class).to receive(:parse_env).with([:test]).and_call_original
        described_class.parse(@gemfile, :test)
      end

      it "evaluates gemfile with bundler dsl" do
        expect(Bundler::Dsl).to receive(:evaluate).with(@gemfile, nil, true).and_call_original
        described_class.parse(@gemfile, :test)
      end

      it "processes gemfile / returns results" do
        env = Object.new
        gemfile = Object.new
        expect(described_class).to receive(:parse_env).and_return(env)
        expect(Bundler::Dsl).to receive(:evaluate).and_return(gemfile)
        expect(described_class).to receive(:process).with(gemfile, env)
        described_class.parse(@gemfile, :test)
      end
    end
  end # describe Gemfile
end # module BundlerExt
