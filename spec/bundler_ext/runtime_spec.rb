require 'spec_helper'
require 'bundler_ext/runtime'

module BundlerExt
  describe Runtime do
    describe "#gemfile" do
      it "gets/sets bext_gemfile" do
        runtime = described_class.new
        expect(runtime.gemfile('Gemfile.in')).to eq('Gemfile.in')
        expect(runtime.gemfile).to eq('Gemfile.in')
      end

      it "defaults to Bundler.default_gemfile" do
        expect(Bundler).to receive(:default_gemfile).and_return('DefaultGemfile')
        runtime = described_class.new
        expect(runtime.gemfile).to eq('DefaultGemfile')
      end
    end

    describe "#root" do
      it "returns directory name of gemfile" do
        runtime = described_class.new
        runtime.gemfile(Pathname.new('spec/fixtures/Gemfile.in'))
        expect(runtime.root.to_s).to eq(File.expand_path('spec/fixtures'))
      end
    end

    describe "#bundler" do
      it "returns handle to bundler runtime" do
        runtime = described_class.new
        runtime.gemfile(Pathname.new('spec/fixtures/Gemfile.in'))
        bundler = runtime.bundler
        expect(bundler).to be_an_instance_of(Bundler::Runtime)
        expect(bundler.root.to_s).to eq(File.expand_path('spec/fixtures'))
        expect(runtime.bundler).to eq(bundler)
      end
    end

    describe "#rubygems" do
      it "returns handle to bundler rubygems integration" do
        runtime  = described_class.new
        rubygems = runtime.rubygems
        expect(rubygems).to be_an_instance_of(Bundler::RubygemsIntegration)
        expect(runtime.rubygems).to eq(rubygems)
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
        expect(ENV['HOME']).to eq('/home/foo')
      end

      it "assigns env home variable to BUNDLER_EXT_HOME" do
        ENV['BUNDLER_EXT_HOME'] = '/home/foo'
        described_class.new.setup_env
        expect(ENV['HOME']).to eq('/home/foo')
      end
    end

    describe "::namespaced_file" do
      context "file does not include '-'" do
        it "returns nil" do
          expect(described_class.namespaced_file('foobar')).to be_nil
        end
      end

      context "file responds to :name" do
        it "returns file name in path format" do
          file = Pathname.new 'foo-bar'
          expect(file).to receive(:name).and_return('foo-bar')
          expect(described_class.namespaced_file(file)).to eq('foo/bar')
        end
      end

      it "returns file in path format" do
        expect(described_class.namespaced_file("foo-bar")).to eq('foo/bar')
      end
    end

    describe "#system_require" do
      it "requires files" do
        runtime = described_class.new
        expect(runtime).to receive(:require).with('file1')
        runtime.system_require(['file1'])
      end

      context "LoadError when requiring file" do
        it "requires namespaced file" do
          expect(described_class).to receive(:namespaced_file).with('file1').
            and_return('namespaced_file1')
          runtime = described_class.new
          expect(runtime).to receive(:require).with('file1').and_call_original
          expect(runtime).to receive(:require).with('namespaced_file1')
          runtime.system_require(['file1'])
        end

        context "LoadError when requiring namespaced file" do
          it "outputs strict error" do
            expected = 'Gem loading error: cannot load such file -- namespaced_file1'
            expect(Output).to receive(:strict_err).with(expected)

            expect(described_class).to receive(:namespaced_file).with('file1').
              and_return('namespaced_file1')
            runtime = described_class.new
            expect(runtime).to receive(:require).with('file1').and_call_original
            expect(runtime).to receive(:require).with('namespaced_file1').and_call_original
            runtime.system_require(['file1'])
          end
        end

        context "namespaced file is nil" do
          it "outputs strict error" do
            expected = 'Gem loading error: cannot load such file -- file1'
            expect(Output).to receive(:strict_err).with(expected)

            expect(described_class).to receive(:namespaced_file).with('file1').
              and_return(nil)
            runtime = described_class.new
            expect(runtime).to receive(:require).with('file1').and_call_original
            runtime.system_require(['file1'])
          end
        end
      end
    end

    describe "clear" do
      it "cleans bundler load path" do
        runtime = described_class.new
        expect(runtime.bundler).to receive(:clean_load_path)
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
        expect(runtime.rubygems).to receive(:mark_loaded).with(spec)
        runtime.add_spec(spec)
      end

      it "adds spec load paths not already on LOAD_PATH to it" do
        $LOAD_PATH.clear
        spec = Gem::Specification.new :load_paths => ['foo']
        runtime.add_spec(spec)
        expect($LOAD_PATH).to eq(spec.load_paths)
      end

      it "skips paths already on the $LOAD_PATH" do
        spec = Gem::Specification.new :load_paths => ['foo']
        $LOAD_PATH.clear
        $LOAD_PATH << spec.load_paths.first
        runtime.add_spec(spec)
        expect($LOAD_PATH.size).to eq(1)
      end
    end
  end # describe Runtime
end # module BundlerExt
