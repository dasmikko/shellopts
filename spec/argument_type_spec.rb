
require 'fileutils'

include ShellOpts::Grammar

describe "ShellOpts" do
  describe "Grammar" do
    describe "FileArgument" do
      def match(kind, node)
        matcher = FileArgument.new(kind)
        matcher.match?("opt", node) || false
      end

      def root() Dir.getwd + "/spec/tmpdir" end

      def file() root + "/file" end
      def dir() root + "/dir" end
      def path() root + "/path" end # A symlink

      def nfile() root + "/nfile" end
      def ndir() root + "/ndir" end
      def npath() root + "/npath" end

      def tty() root + "/cdev" end
      def null() root + "/not_here/node" end

      before(:all) {
        FileUtils.rm_rf root
        FileUtils.mkdir_p root
        FileUtils.mkdir dir
        FileUtils.touch file
        FileUtils.ln_s "/dev/tty", tty
      }

      # Only remove temporary directory if all tests succeeded
      after(:all) { |example_group|
        all_groups = example_group.class.descendants
        failed_examples = all_groups.map(&:examples).flatten.select(&:exception)
        FileUtils.rm_rf root if failed_examples.empty?
      }

      context "when kind is :file" do
        it "accepts an existing file" do
          expect(match(:file, file)).to eq true
        end
        it "accepts a missing file" do
          expect(match(:file, nfile)).to eq true
        end
        it "fails if not a regular file" do
          expect(match(:file, dir)).to eq false
        end
        it "fails if enclosing directory doesn't exists" do
          expect(match(:file, null)).to eq false
        end
      end

      context "when kind is :dir" do
        it "accepts an existing dir" do
          expect(match(:dir, dir)).to eq true
        end
        it "accepts a missing dir" do
          expect(match(:dir, ndir)).to eq true
        end
        it "fails if not a regular dir" do
          expect(match(:dir, file)).to eq false
        end
        it "fails if enclosing directory doesn't exists" do
          expect(match(:dir, null)).to eq false
        end
      end

      context "when kind is :path" do
        it "accepts an existing file" do
          expect(match(:path, file)).to eq true
        end
        it "accepts an existing dir" do
          expect(match(:path, dir)).to eq true
        end
        it "accepts a missing node" do
          expect(match(:path, ndir)).to eq true
        end
        it "fails if not a regular file or directory" do
          expect(match(:path, tty)).to eq false
        end
        it "fails if enclosing directory doesn't exists" do
          expect(match(:path, null)).to eq false
        end
      end

      context "when kind is :efile" do
        it "accepts an existing file" do
          expect(match(:efile, file)).to eq true
        end
        it "fails if file is not a regular  file" do
          expect(match(:efile, nfile)).to eq false
        end
        it "fails if not a regular file" do
          expect(match(:efile, dir)).to eq false
        end
      end

      context "when kind is :edir" do
        it "accepts an existing dir" do
          expect(match(:edir, dir)).to eq true
        end
        it "fails if dir is not a directory" do
          expect(match(:edir, ndir)).to eq false
        end
        it "fails if not a regular dir" do
          expect(match(:edir, file)).to eq false
        end
      end

      context "when kind is :epath" do
        it "accepts an existing file" do
          expect(match(:epath, file)).to eq true
        end
        it "accepts an existing dir" do
          expect(match(:epath, dir)).to eq true
        end
        it "fails if node is missing" do
          expect(match(:epath, ndir)).to eq false
        end
        it "fails if not a regular file or directory" do
          expect(match(:epath, tty)).to eq false
        end
      end

      context "when kind is :nfile" do
        it "fails if file exists" do
          expect(match(:nfile, file)).to eq false
        end
        it "accepts a missing file" do
          expect(match(:nfile, nfile)).to eq true
        end
        it "fails if enclosing directory doesn't exists" do
          expect(match(:nfile, null)).to eq false
        end
      end

      context "when kind is :ndir" do
        it "fails if file exists" do
          expect(match(:ndir, dir)).to eq false
        end
        it "accepts a missing dir" do
          expect(match(:ndir, ndir)).to eq true
        end
        it "fails if enclosing directory doesn't exists" do
          expect(match(:ndir, null)).to eq false
        end
      end

      context "when kind is :npath" do
        it "fails if path exists" do
          expect(match(:npath, file)).to eq false
          expect(match(:npath, dir)).to eq false
        end
        it "accepts a missing file or directory" do
          expect(match(:npath, ndir)).to eq true
        end
        it "fails if enclosing directory doesn't exists" do
          expect(match(:npath, null)).to eq false
        end
      end
    end
  
    describe "EnumArgument" do
      let(:e) { EnumArgument.new %w(alpha beta) }
      describe "#values" do
        it "returns a list of allowed values" do
          expect(e.values).to eq %w(alpha beta) 
        end
      end
      describe "#match?" do
        it "returns true if the given value is an enum" do
          expect(e.match?("name", "alpha")).to eq true
        end
        context "when the given value is not an enum" do
          it "returns false" do
            expect(e.match?("name", "futhark")).to eq false
          end
          it "sets the message of the ArgumentType" do
            e.match?("name", "futhark")
            expect(e.message).to eq "Illegal value in name: 'futhark'"
          end
        end
      end
      describe "#value?" do
        it "returns true if the given value is an enum and false otherwise" do
          expect(e.value?("alpha")).to eq true
          expect(e.value?("futhark")).to eq false
        end
      end
    end
  end
end















