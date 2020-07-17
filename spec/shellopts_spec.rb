require 'spec_helper.rb'
require 'shellopts.rb'

describe "Requiring shellopts" do
  it "defines a global PROGRAM constant" do
    expect(PROGRAM).to eq "rspec"
  end
end

include ShellOpts

# For access to ShellOpts.@shellopts
module ShellOpts
  def self.get_state() @shellopts end
end

shared_examples_for "the error method" do |test_global|
  it "writes the error message and a usage string to stderr" do
    expected = "cmd: Error message\nUsage: cmd -a\n"
    expect {
      begin
        subject.error("Error message")
      rescue SystemExit
      end
    }.to output(expected).to_stderr
  end

  it "terminates the program with exit code 1" do
    $stderr = StringIO.new
    expect { subject.error("Error message") }.to raise_error(SystemExit) do |error|
      expect(error.status).to eq(1)
    end
  end
end

shared_examples_for "the fail method" do
  it "writes the error message to stderr" do
    expected = "cmd: Error message\n"
    expect {
      begin
        subject.fail("Error message")
      rescue SystemExit
      end
    }.to output(expected).to_stderr
  end

  it "terminates the program with exit code 1" do
    $stderr = StringIO.new
    expect { subject.fail("Error message") }.to raise_error(SystemExit) do |error|
      expect(error.status).to eq(1)
    end
  end
end

describe ShellOpts do
  def process(usage, argv, &block)
    ::ShellOpts.reset
    ::ShellOpts.process(usage, argv, &block)
  end

  it "has a version number" do
    expect(Shellopts::VERSION).to match(/\d+\.\d+\.\d+/)
  end

  describe ".shellopts" do
    it "returns the hidden ShellOpts::ShellOpts object" do
      args = process("a", %w(-a)) {}
      hidden = ShellOpts.shellopts
      expect(args).to be hidden.args
    end
  end

  describe ".usage" do
    let(:shellopts) { process("a", %w()) {}; ShellOpts.shellopts }

    it "defaults to ShellOpts::ShellOpts#usage" do
      expect(shellopts.usage).to eq ShellOpts.usage
    end
    it "can be overridden" do
      shellopts # Force creation
      expect(ShellOpts.usage).to eq "-a"
      ShellOpts.usage = "override"
      expect(ShellOpts.usage).to eq "override"
      ShellOpts.reset
    end
  end

  describe ".process" do
    let(:usage) { "a b= c" }
    let(:argv) { %w(-a -bhello -c ARG) }

    context "with a block" do
      it "returns the remaining arguments" do
        args = process(usage, argv) {}
        expect(args).to eq %w(ARG)
      end
      it "yields a [opt, val] tuple for each option" do
        block_args = []
        process(usage, argv) { |opt, val| block_args << [opt, val] }
        expect(block_args).to eq [["-a", nil], ["-b", "hello"], ["-c", nil]]
      end
      it "yields a [cmd, opt-cmd-array] for each comamnd" do
        arr = []
        process("a cmd! b", %w(-a cmd -b)) { |name, value| arr << [name, value] }
        expect(arr).to eq [["-a", nil], ["cmd", [["-b", nil]]]]
      end
    end

    context "without a block" do
      it "returns a ShellOpts::ShellOpts object" do
        expect(process(usage, argv)).to be_a ShellOpts
      end
    end

    context "when syntax errors in the usage string" do
      it 'raises a ShellOpts::CompilerError' do
        expect { process("a++", "") {} }.to raise_error CompilerError
      end
      it 'sets the backtrace to the calling method' do
        backtrace = []
        expected = ""
        begin
          process("a++", "") {}; expected = "#{__FILE__}:#{__LINE__}"
        rescue Error => ex
          backtrace = ex.backtrace
        end
        expect(backtrace.first).to start_with(expected)
      end
    end

    context "when errors in the user-supplied arguments" do
      it 'terminates the program with an error message'
    end

    context "when errors in the usage of the library" do
      it 'raise a ShellOpts::InternalError' do
        expect {
          ::ShellOpts.process(usage, argv) {}
          ::ShellOpts.process(usage, argv) {}
        }.to raise_error InternalError
      end
    end
  end

  describe ".reset" do
    it "resets ShellOpts" do
      process("a", %w(-a)) {}
      expect(::ShellOpts.get_state).not_to eq nil
      ShellOpts.reset
      expect(::ShellOpts.get_state).to eq nil
    end
  end

  describe ".error" do
    subject {
      ShellOpts.reset
      ShellOpts.process("a", %w(-a), program_name: "cmd") {}
      ShellOpts
    }
    it_should_behave_like("the error method")

    context "when ShellOpts hasn't been initialized" do
      it "use the global USAGE string if defined" do
        ::ShellOpts.reset
        stub_const("USAGE", "a")
        expected = "rspec: Error message\nUsage: rspec -a\n"
        expect {
          begin
            ::ShellOpts.error("Error message")
          rescue SystemExit
          end
        }.to output(expected).to_stderr
      end

      it "omits the usage if the USAGE is undefined" do
        ::ShellOpts.reset
        hide_const("USAGE")
        expected = "rspec: Error message\n"
        expect {
          begin
            ::ShellOpts.error("Error message")
          rescue SystemExit
          end
        }.to output(expected).to_stderr
      end

      it "use the global PROGRAM string as name" do
        ::ShellOpts.reset
        hide_const("USAGE")
        stub_const("PROGRAM", "program")
        expected = "program: Error message\n"
        expect {
          begin
            ::ShellOpts.error("Error message")
          rescue SystemExit
          end
        }.to output(expected).to_stderr
      end
    end
  end

  describe ".fail" do
    subject {
      ShellOpts.reset
      ShellOpts.process("a", %w(-a), program_name: "cmd") {}
      ShellOpts
    }
    it_should_behave_like("the fail method")

  end

  describe "ShellOpts" do
    describe "#initialize" do
      context "on errors in the usage string" do
        it "raises a CompilerError" do
          expect { ShellOpts::ShellOpts.new("-", %w(-b)) }.to raise_error ShellOpts::CompilerError
        end
      end
      context "on errors in the arguments" do
        it "terminates the program" do
          expect { ShellOpts::ShellOpts.new("a", %w(-b)) }.to raise_error(SystemExit)
        end
      end
    end

    describe "#program_name" do
      it "is the name of the program" do
        shellopts = ShellOpts::ShellOpts.new("a", %w(-a), program_name: "Program name")
        expect(shellopts.program_name).to eq "Program name"
      end
      it "defaults to the command line name" do
        shellopts = ShellOpts::ShellOpts.new("a", %w(-a))
        expect(shellopts.program_name).to eq "rspec"
      end
    end

    describe "#usage" do
      it "is the usage string" do
        shellopts = ShellOpts::ShellOpts.new("a b=FILE cmd! interactive l", %w(-a))
        expect(shellopts.usage).to eq "-a -b=FILE cmd --interactive -l"
      end
    end

    describe "#grammar" do
      it "is the grammar of the program" do
        shellopts = ShellOpts::ShellOpts.new("a", %w(-a))
        expect(shellopts.grammar).to be_a Grammar::Program
      end
    end

    describe "#ast" do
      it "is the AST of the command line" do
        shellopts = ShellOpts::ShellOpts.new("a", %w(-a))
        expect(shellopts.ast).to be_a Ast::Program
      end
    end

    describe "#to_a" do
      it "serializes the AST to a recursive array" do
        shellopts = ShellOpts::ShellOpts.new("a cmd! b", %w(-a cmd -b))
        arr = []
        shellopts.each { |name, value| arr << [name, value] }
        expect(arr).to eq [["-a", nil], ["cmd", [["-b", nil]]]]
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
        it "serializes the AST to a recursive array" do
          res = ShellOpts::ShellOpts.new("a cmd! b", %w(-a cmd -b)).each
          arr = [["-a", nil], ["cmd", [["-b", nil]]]]
          expect(res).to eq arr
        end
      end
    end

    describe "#error" do
      subject {
        ShellOpts::ShellOpts.new("a", %w(-a), program_name: "cmd")
      }
      it_should_behave_like("the error method")
    end

    describe "#fail" do
      subject {
        ShellOpts::ShellOpts.new("a", %w(-a), program_name: "cmd")
      }
      it_should_behave_like("the fail method")
    end
  end
end



