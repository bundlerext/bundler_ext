require 'spec_helper'
require 'bundler_ext/runtime'

module BundlerExt
  describe Runtime do
    describe "#gemfile" do
      it "gets/sets bext_gemfile" do
        runtime = described_class.new
        runtime.gemfile('Gemfile.in').should == 'Gemfile.in'
        runtime.gemfile.should == 'Gemfile.in'
      end

      it "defaults to Bundler.default_gemfile" do
        Bundler.should_receive(:default_gemfile).and_return('DefaultGemfile')
        runtime = described_class.new
        runtime.gemfile.should == 'DefaultGemfile'
      end
    end

    describe "#root" do
      it "returns directory name of gemfile" do
        runtime = described_class.new
        runtime.gemfile(Pathname.new('spec/fixtures/Gemfile.in'))
        runtime.root.to_s.should == File.expand_path('spec/fixtures')
      end
    end

    describe "#bundler" do
      it "returns handle to bundler runtime" do
        runtime = described_class.new
        runtime.gemfile(Pathname.new('spec/fixtures/Gemfile.in'))
        bundler = runtime.bundler
        bundler.should be_an_instance_of(Bundler::Runtime)
        bundler.root.to_s.should == File.expand_path('spec/fixtures')
        runtime.bundler.should == bundler
      end
    end

    describe "#rubygems" do
      it "returns handle to bundler rubygems integration" do
        runtime  = described_class.new
        rubygems = runtime.rubygems
        rubygems.should be_an_instance_of(Bundler::RubygemsIntegration)
        runtime.rubygems.should == rubygems
      end
    end

    describe "#setup_env" do
      around(:each) do |spec|
        orig = ENV
        spec.run
        ENV = orig
      end

      it "assigns env home variable to BEXT_HOME" do
        ENV['BEXT_HOME'] = '/home/foo'
        described_class.new.setup_env
        ENV['HOME'].should == '/home/foo'
      end

      it "assigns env home variable to BUNDLER_EXT_HOME" do
        ENV['BUNDLER_EXT_HOME'] = '/home/foo'
        described_class.new.setup_env
        ENV['HOME'].should == '/home/foo'
      end
    end

    describe "::namespaced_file" do
      context "file does not include '-'" do
        it "returns nil" do
          described_class.namespaced_file('foobar').should be_nil
        end
      end

      context "file responds to :name" do
        it "returns file name in path format" do
          file = Pathname.new 'foo-bar'
          file.should_receive(:name).and_return('foo-bar')
          described_class.namespaced_file(file).should == 'foo/bar'
        end
      end

      it "returns file in path format" do
        described_class.namespaced_file("foo-bar").should == 'foo/bar'
      end
    end

    describe "#system_require" do
      it "requires files" do
        runtime = described_class.new
        runtime.should_receive(:require).with('file1')
        runtime.system_require(['file1'])
      end

      context "LoadError when requiring file" do
        it "requires namespaced file" do
          described_class.should_receive(:namespaced_file).with('file1').
            and_return('namespaced_file1')
          runtime = described_class.new
          runtime.should_receive(:require).with('file1').and_call_original
          runtime.should_receive(:require).with('namespaced_file1')
          runtime.system_require(['file1'])
        end

        context "LoadError when requiring namespaced file" do
          it "outputs strict error" do
            expected = 'Gem loading error: cannot load such file -- namespaced_file1'
            Output.should_receive(:strict_err).with(expected)

            described_class.should_receive(:namespaced_file).with('file1').
              and_return('namespaced_file1')
            runtime = described_class.new
            runtime.should_receive(:require).with('file1').and_call_original
            runtime.should_receive(:require).with('namespaced_file1').and_call_original
            runtime.system_require(['file1'])
          end
        end

        context "namespaced file is nil" do
          it "outputs strict error" do
            expected = 'Gem loading error: cannot load such file -- file1'
            Output.should_receive(:strict_err).with(expected)

            described_class.should_receive(:namespaced_file).with('file1').
              and_return(nil)
            runtime = described_class.new
            runtime.should_receive(:require).with('file1').and_call_original
            runtime.system_require(['file1'])
          end
        end
      end
    end

    describe "clear" do
      it "cleans bundler load path" do
        runtime = described_class.new
        runtime.bundler.should_receive(:clean_load_path)
        runtime.clear
      end
    end

    describe "add_spec" do
      around(:each) do |spec|
        orig = $LOAD_PATH.dup
        spec.run

        # XXX need to restore this way else we'll get an err:
        #   "$LOAD_PATH is a read-only variable"
        $LOAD_PATH.clear
        orig.each { |o| $LOAD_PATH << o }
      end

      # XXX needed to require rubygems/ext/builder in with Bundler 1.8.1+.
      let!(:runtime) { described_class.new.tap {|c| c.rubygems} }

      it "marks spec as loaded" do
        spec = Gem::Specification.new
        runtime.rubygems.should_receive(:mark_loaded).with(spec)
        runtime.add_spec(spec)
      end

      it "adds spec load paths not already on LOAD_PATH to it" do
        $LOAD_PATH.clear
        spec = Gem::Specification.new :load_paths => ['foo']
        runtime.add_spec(spec)
        $LOAD_PATH.should include(*spec.load_paths)
      end

      it "skips paths already on the $LOAD_PATH" do
        spec = Gem::Specification.new :load_paths => ['foo']
        $LOAD_PATH.clear
        $LOAD_PATH << spec.load_paths.first
        runtime.add_spec(spec)
        $LOAD_PATH.size.should == 1
      end
    end
  end # describe Runtime
end # module BundlerExt
