
require 'spec_helper.rb'

require 'shellopts/shellopts.rb'
require 'shellopts/option_struct.rb'

describe "ShellOpts::ShellOpts" do
  describe "#initialize" do
    context "on errors in the spec string" do
      it "raises a CompilerError" do
        expect { ShellOpts::ShellOpts.new("-", %w(-b)) }.to raise_error ShellOpts::CompilerError
      end
    end
    context "on errors in the arguments" do
      it "raises a UserError" do
        allow(STDERR).to receive(:print) # Silence #error
        shellopts = ShellOpts::ShellOpts.new("a", %w(-b))
        expect { shellopts.process }.to raise_error(ShellOpts::UserError)
      end
    end
  end

  describe "#name" do
    it "is the name of the program" do
      shellopts = ShellOpts::ShellOpts.new("a", %w(-a), name: "Program name")
      expect(shellopts.name).to eq "Program name"
    end
    it "defaults to the command line name" do
      shellopts = ShellOpts::ShellOpts.new("a", %w(-a))
      expect(shellopts.name).to eq "rspec"
    end
  end

  describe "#spec" do
    it "describe the usage of the program" do
      shellopts = ShellOpts::ShellOpts.new("a -- FILE", %w(-a))
      expect(shellopts.usage).to eq "-a FILE"
    end
  end

  describe "#grammar" do
    it "is the grammar of the program" do
      shellopts = ShellOpts::ShellOpts.new("a", %w(-a))
      expect(shellopts.grammar).to be_a ShellOpts::Grammar::Program
    end
  end

  describe "#ast" do
    it "is the AST of the command line" do
      shellopts = ShellOpts::ShellOpts.new("a", %w(-a)).process
      expect(shellopts.ast).to be_a ShellOpts::Ast::Program
    end
  end

  # TODO: Make to_a check for ...
#   context "with a block" do
#     it "returns the remaining arguments" do
#       args = process(spec, argv) {}
#       expect(args).to eq %w(ARG)
#     end
#     it "yields a [opt, val] tuple for each option" do
#       block_args = []
#       process(spec, argv) { |opt, val| block_args << [opt, val] }
#       expect(block_args).to eq [["-a", nil], ["-b", "hello"], ["-c", nil]]
#     end
#     it "yields a [cmd, opt-cmd-array] for each comamnd" do
#       arr = []
#       process("a cmd! b", %w(-a cmd -b)) { |name, value| arr << [name, value] }
#       expect(arr).to eq [["-a", nil], ["cmd", [["-b", nil]]]]
#     end
#   end

  describe "#to_a" do
    it "serializes the AST to a recursive array" do
      shellopts = ShellOpts::ShellOpts.new("a cmd! b", %w(-a cmd -b)).process
      arr = []
      shellopts.to_a.each { |name, value| arr << [name, value] }
      expect(arr).to eq [["-a", nil], ["cmd", [["-b", nil]]]]
    end
  end

  describe "#to_h" do
    it "returns an OptionsHash representation of the AST" do
      shellopts = ShellOpts::ShellOpts.new("a", %w(-a)).process
      expect(shellopts.to_h).to be_a Hash
    end
  end

  describe "#to_struct" do
    it "returns an OptionStruct representation of the AST" do
      shellopts = ShellOpts::ShellOpts.new("a", %w(-a)).process
      expect(ShellOpts::OptionStruct.class_of(shellopts.to_struct)).to be ShellOpts::OptionStruct
    end
  end

  describe "#args" do
    it "returns a Args object" do
      shellopts = ShellOpts::ShellOpts.new("a", %w(-a ARG1 ARG2)).process
      expect(shellopts.args).to be_a ShellOpts::Args
      expect(shellopts.args).to eq ["ARG1", "ARG2"]
    end
  end

  describe "#each" do
    context "with a block" do
      it "iterates option/command tuples" do
        shellopts = ShellOpts::ShellOpts.new("a cmd! b", %w(-a cmd -b)).process
        arr = []
        shellopts.each { |name, value| arr << [name, value] }
        expect(arr).to eq [["-a", nil], ["cmd", [["-b", nil]]]]
      end
    end
    context "without a block" do
      it "serializes the AST to a recursive array enumerator" do
        res = ShellOpts::ShellOpts.new("a cmd! b", %w(-a cmd -b)).process.each
        expect(res).to be_a Enumerator
        arr = [["-a", nil], ["cmd", [["-b", nil]]]]
        expect(res.to_a).to eq arr
      end
    end
  end

  describe "#error" do
    let(:shellopts) { ShellOpts::ShellOpts.new("a b -- FILE", [], name: "cmd").process }

    def expect_error(message = "Error message")
      expect {
        begin
          shellopts.error message
        rescue SystemExit
        end
      }
    end

    it "terminates the program with status 1" do
      allow(STDERR).to receive(:puts) # Silence #error
      expect { shellopts.error("Error message") }.to raise_error SystemExit
    end

    it "writes the message on stderr" do
      expected = "cmd: Error message\nUsage: cmd -a -b FILE\n"
      expect_error.to output(expected).to_stderr
    end

    it "doesn't exit if exit: is false" do
      allow(STDERR).to receive(:puts) # Silence #error
      expect { shellopts.error("Error message", exit: false) }.not_to raise_error
    end

    context "when #usage has been assigned to" do
      it "prints the usage as is" do
        shellopts.usage = "Usage description"
        expected = "cmd: Error message\nUsage description\n"
        expect_error.to output(expected).to_stderr
      end
      it "strips suffixed whitespace" do
        shellopts.usage = ""
        expected = "cmd: Error message\n"
        expect_error.to output(expected).to_stderr
      end
    end
  end

  describe "#fail" do
    let(:shellopts) { ShellOpts::ShellOpts.new("a b -- FILE", [], name: "cmd") }

    def expect_fail(message = "Error message")
      expect {
        begin
          shellopts.fail message
        rescue SystemExit
        end
      }
    end

    it "terminates the program with status 1" do
      allow(STDERR).to receive(:puts) # Silence #error
      expect { shellopts.fail("Error message") }.to raise_error SystemExit
    end

    it "writes the message on stderr" do
      expected = "cmd: Error message\n"
      expect_fail.to output(expected).to_stderr
    end
  end
end

