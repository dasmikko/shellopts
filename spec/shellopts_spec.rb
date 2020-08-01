require 'spec_helper.rb'
require 'shellopts.rb'

shared_examples 'as_* methods' do |method, forward_method, result_class|
  let(:cmd) { ShellOpts.send(method, "a", %w(ARG)) }

  it "sets the current shellopts object" do
    ShellOpts.reset
    expect(ShellOpts.shellopts).to be nil
    program, args = cmd
    expect(ShellOpts.shellopts).not_to be nil
  end

  it "forwards to ShellOpts::ShellOpts##{forward_method}" do
    ShellOpts.process("a", [])
    shellopts = ShellOpts.shellopts
    expect(ShellOpts).to receive(:process) {}
    expect(shellopts).to receive(forward_method)
    ShellOpts.send(method, "a", [])
  end

  if result_class
    it "returns a [#{result_class}, args] tuple" do
      program, args = cmd

      # 'expect(program).to be_a result_class' doesn't work for OptionStruct
      # objects
      klass = ::Kernel.instance_method(:class).bind(program).call 
      expect(klass <= result_class).to be true

      expect(args).to eq ["ARG"]
    end
  end

  it "includes the ShellOpts module if called from main" do
    stdout = `spec/scripts/auto_include_shellopts.rb '#{method}("a", %w(-a))'`.chomp
    expect(stdout).to eq "ShellOpts is included"
  end
end

describe "Requiring shellopts" do
  it "defines the global PROGRAM constant" do
    expect(PROGRAM).to eq "rspec"
  end
end

describe ShellOpts do
  def process(spec, argv, &block)
    ::ShellOpts.reset
    ::ShellOpts.process(spec, argv, &block)
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
    let(:spec) { "a b= c" }
    let(:argv) { %w(-a -bhello -c ARG) }


    it "returns a ShellOpts object" do
      expect(process(spec, argv)).to be_a ShellOpts::ShellOpts
    end
  end

  describe ".as_program" do
    include_examples 'as_* methods', :as_program, :idr, ShellOpts::Idr::Program
  end

  describe ".as_array" do
    include_examples 'as_* methods', :as_array, :to_a, Array
  end

  describe ".as_hash" do
    include_examples 'as_* methods', :as_hash, :to_h, Hash
  end

  describe ".as_struct" do
    include_examples 'as_* methods', :as_struct, :to_struct, ShellOpts::OptionStruct
  end

  describe ".each" do
    include_examples 'as_* methods', :as_struct, :to_struct, nil
  end

  context "when syntax errors in the spec string" do
    it 'raises a ShellOpts::CompilerError' do
      expect { process("a++", "") {} }.to raise_error ShellOpts::CompilerError
    end
    it 'sets the backtrace to the calling method' do
      backtrace = []
      expected = ""
      begin
        process("a++", "") {}; expected = "#{__FILE__}:#{__LINE__}"
      rescue ShellOpts::Error => ex
        backtrace = ex.backtrace
      end
      expect(backtrace.first).to start_with(expected)
    end
  end

  context "when errors in the user-supplied arguments" do
    it 'terminates the program with an error message' do
      expect { process("a", %w(-b)) }.to raise_error ShellOpts::UserError
    end
  end

  context "when errors in the spec of the library" do
    it 'raise a ShellOpts::InternalError' do
      expect { ShellOpts.error }.to raise_error ShellOpts::InternalError
    end
  end
  context "when ShellOpts is included" do
    it "defines an #error method"
    it "defines a #fail method"

    it "captures UserError exceptions" do
      output = `spec/scripts/raise_shellopts_exception.rb ShellOpts::UserError 2>&1`
      expect(output.split('\n').first).to match /^.*: ShellOpts::UserError handled/
    end
    it "captures SystemFail exceptions" do
      output = `spec/scripts/raise_shellopts_exception.rb ShellOpts::SystemFail 2>&1`
      expect(output.split('\n').first).to match /^.*: ShellOpts::SystemFail handled/
    end
  end
end
