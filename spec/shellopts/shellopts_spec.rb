
require 'spec_helper.rb'

require 'shellopts/shellopts.rb'
require 'shellopts/option_struct.rb'

describe "ShellOpts::ShellOpts" do
  describe "#initialize" do
    context "on errors in the usage string" do
      it "raises a CompilerError" do
        expect { ShellOpts::ShellOpts.new("-", %w(-b)) }.to raise_error ShellOpts::CompilerError
      end
    end
    context "on errors in the arguments" do
      it "raises a UserError" do
        allow(STDERR).to receive(:print) # Silence #error
        expect { ShellOpts::ShellOpts.new("a", %w(-b)) }.to raise_error(ShellOpts::UserError)
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

  describe "#grammar" do
    it "is the grammar of the program" do
      shellopts = ShellOpts::ShellOpts.new("a", %w(-a))
      expect(shellopts.grammar).to be_a ShellOpts::Grammar::Program
    end
  end

  describe "#ast" do
    it "is the AST of the command line" do
      shellopts = ShellOpts::ShellOpts.new("a", %w(-a))
      expect(shellopts.ast).to be_a ShellOpts::Ast::Program
    end
  end

  # TODO: Make to_a check for ...
#   context "with a block" do
#     it "returns the remaining arguments" do
#       args = process(usage, argv) {}
#       expect(args).to eq %w(ARG)
#     end
#     it "yields a [opt, val] tuple for each option" do
#       block_args = []
#       process(usage, argv) { |opt, val| block_args << [opt, val] }
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
      shellopts = ShellOpts::ShellOpts.new("a cmd! b", %w(-a cmd -b))
      arr = []
      shellopts.to_a.each { |name, value| arr << [name, value] }
      expect(arr).to eq [["-a", nil], ["cmd", [["-b", nil]]]]
    end
  end

  describe "#to_h" do
    it "returns an OptionsHash representation of the AST" do
      shellopts = ShellOpts::ShellOpts.new("a", %w(-a))
      expect(shellopts.to_h).to be_a Hash
    end
  end

  describe "#to_struct" do
    it "returns an OptionStruct representation of the AST" do
      shellopts = ShellOpts::ShellOpts.new("a", %w(-a))
      expect(ShellOpts::OptionStruct.class_of(shellopts.to_struct)).to be ShellOpts::OptionStruct
    end
  end

  describe "#args" do
    it "returns a Args object" do
      shellopts = ShellOpts::ShellOpts.new("a", %w(-a ARG1 ARG2))
      expect(shellopts.args).to be_a ShellOpts::Args
      expect(shellopts.args).to eq ["ARG1", "ARG2"]
    end
  end

  describe "#each" do
    context "with a block" do
      it "iterates option/command tuples" do
        shellopts = ShellOpts::ShellOpts.new("a cmd! b", %w(-a cmd -b))
        arr = []
        shellopts.each { |name, value| arr << [name, value] }
        expect(arr).to eq [["-a", nil], ["cmd", [["-b", nil]]]]
      end
    end
    context "without a block" do
      it "serializes the AST to a recursive array enumerator" do
        res = ShellOpts::ShellOpts.new("a cmd! b", %w(-a cmd -b)).each
        expect(res).to be_a Enumerator
        arr = [["-a", nil], ["cmd", [["-b", nil]]]]
        expect(res.to_a).to eq arr
      end
    end
  end

  describe "#error" do
    it "forwards to @message.error" do
      shellopts = ShellOpts::ShellOpts.new("a", %w(-a))
      expect(shellopts.messenger).to receive(:error)
      begin
        shellopts.error("Error message")
      rescue SystemExit
      end
    end
    
  end

  describe "#fail" do
    it "forwards to @message.fail" do
      shellopts = ShellOpts::ShellOpts.new("a", %w(-a))
      expect(shellopts.messenger).to receive(:fail)
      begin
        shellopts.fail("Error message") 
      rescue SystemExit
      end
    end
  end
end

