require 'spec_helper.rb'
require 'shellopts.rb'

describe "Requiring shellopts" do
  it "defines the global PROGRAM constant" do
    expect(PROGRAM).to eq "rspec"
  end
end

include ShellOpts

describe ShellOpts do
  def process(usage, argv, &block)
    ::ShellOpts.reset
    ::ShellOpts.process(usage, argv, &block)
  end

  it "has a version number" do
    expect(Shellopts::VERSION).to match(/\d+\.\d+\.\d+/)
  end

  describe ".shellopts" do
    it "returns the ShellOpts::ShellOpts object" do
      shellopts = process("a", %w(-a))
      expect(ShellOpts.shellopts).to be shellopts
    end
  end

  describe ".process" do
    let(:usage) { "a b= c" }
    let(:argv) { %w(-a -bhello -c ARG) }

    it "returns a ShellOpts object" do
      expect(process(usage, argv)).to be_a ShellOpts::ShellOpts
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
    it 'terminates the program with an error message' do
      expect { process("a", "-b") }.to raise SystemExit
    end
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
