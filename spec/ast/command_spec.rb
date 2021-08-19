require 'spec_helper.rb'

include ShellOpts

class State
  def self.opts() @opts end
  def self.opts=(value) @opts = value end
  def self.args() @args end
  def self.args=(value) @args = value end
end

def process(*args)
  spec = args.shift
  State.opts, State.args = ShellOpts.process(spec, args)
end

def opts() State.opts end
def args() State.args end


describe ShellOpts::Ast::Command do
  it "has a #name? method for each option" do
    process("-a", "-a")
    expect { opts.a? }.not_to raise_error
  end
  it "has a #name method for each option with arguments" do
    process("-a=ARG", "-aARG")
    expect { opts.a }.not_to raise_error
    expect(opts.a).to eq "ARG"
  end
  it "has a #name= method for each option with arguments" do
    process("-a=ARG", "-aARG")
    expect { opts.a = "value" }.not_to raise_error
    expect(opts.a).to eq "value"
  end
  it "has a #name method for each repeated option" do
    process("+a=ARG", "-aARG1", "-aARG2")
    expect { opts.a }.not_to raise_error
    expect(opts.a).to eq %w(ARG1 ARG2)
  end
  it "has a #name= method for each repeated option" do
    process("+a=ARG", "-aARG1", "-aARG2")
    expect { opts.a = %w(arg1 arg2) }.not_to raise_error
    expect(opts.a).to eq %w(arg1 arg2)
  end

  describe "#[]" do
    it "reads the option" do
      process("-a=ARG", "-aarg")
      expect(opts.a).to eq "arg"
    end
  end
  describe "#[]=" do
    it "assigns a value to the option" do
      process("-a=ARG", "-aarg")
      opts.a = "another"
      expect(opts.a).to eq "another"
    end
  end
end
