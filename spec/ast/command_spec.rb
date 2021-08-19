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
  # TODO: Move some tests to Options
  it "has a #name? method for each option" do
    process("-a", "-a")
    expect { opts.a? }.not_to raise_error
  end
  it "has a #name method for unique and repeated options" do
    process("-a=ARG +b", "-aARG")
    expect { opts.a }.not_to raise_error
    expect { opts.b }.not_to raise_error
  end
  it "has a #name= method for each unique option with arguments" do
    process("-a=ARG", "-aARG")
    expect { opts.a = "value" }.not_to raise_error
  end
  it "has a #name= method for each repeated option with arguments" do
    process("+a=ARG", "-aARG1", "-aARG2")
    expect { opts.a = %(arg1 arg2) }.not_to raise_error
  end
  
  describe "\"#option\" methods" do
    context "repeated options:" do
      context "without arguments" do
        it "returns the number of time it was used" do
          process("+a", "-a", "-a")
          expect(opts.a).to eq 2
        end
      end
      context "with optional argument" do
        it "returns an array with nil values for missing arguments" do
          process("+a=ARG?", "-aARG1", "-a", "-aARG3")
          expect(opts.a).to eq ["ARG1", nil, "ARG3"]
        end
      end
      context "with mandatory argument" do
        it "returns an array of arguments" do
          process("+a=ARG", "-aARG1", "-aARG2")
          expect(opts.a).to eq %w(ARG1 ARG2)
        end
      end
    end
    describe "unique options:"
    describe "optional options:"
  end




# it "has a #name= method for each repeated option with arguments" do
#   process("+a=ARG", "-aARG1", "-aARG2")
#   expect { opts.a = %w(arg1 arg2) }.not_to raise_error
#   expect(opts.a).to eq %w(arg1 arg2)
# end
# it "as a #name method for each repeated option without arguments" do
#   process("+a", "-a", "-a")
#   expect { opts.a }.not_to raise_error
#   expect(opts.a).to eq 2
#   process("+a", "-a", "-a")
#   expect { opts.a }.not_to raise_error
#   expect(opts.a).to eq 2
# end
# it "has a #name= method for each repeated option without arguments" do
#   process("+a=ARG", "-aARG1", "-aARG2")
#   expect { opts.a = %w(arg1 arg2) }.not_to raise_error
#   expect(opts.a).to eq %w(arg1 arg2)
# end

  describe "#[]" do
    it "returns the value of ds the option" do
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
