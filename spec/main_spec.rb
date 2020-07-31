
require 'spec_helper.rb'

require 'shellopts/main.rb'

describe ShellOpts::Main do
  describe ".main" do
    it "returns the main object" do # TODO Better test
      expect(ShellOpts::Main.main).to be TOPLEVEL_BINDING.eval("self")
    end
    it "defines the CALLER_RE regular expression" do
      expect(ShellOpts::Main::CALLER_RE).to be_a Regexp
    end
  end
end
