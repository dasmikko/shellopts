require 'spec_helper.rb'

require 'shellopts/generator.rb'

include ShellOpts

describe ShellOpts::Idr do
  describe ".generate" do
    it "generates an Idr::Program from a ShellOpts object" do
      shellopts = ShellOpts::ShellOpts.new("a", []).process
      expect(Idr.generate(shellopts)).to be_a Idr::Program
    end
  end
end
