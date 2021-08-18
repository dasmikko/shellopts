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
  describe "#[]" do
    it "reads the option" do
      process("-a=FILE", "-afile")
      expect(opts.a).to eq "file"
    end
  end
  describe "#[]=" do
    it "assigns a value to the option" do
      process("-a=FILE", "-afile")
      opts.a = "another"
      expect(opts.a).to eq "another"
    end
  end
end
