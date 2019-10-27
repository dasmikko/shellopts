require 'spec_helper.rb'

require 'shellopts'
require 'shellopts/utils'

include ShellOpts::Utils

describe "ShellOpts::Utils" do
  describe "#error" do
    it "forwards to ShellOpts.error" do
      allow(::ShellOpts).to receive(:error)
      error("Message")
    end
  end
  describe "#fail" do
    it "forwards to ShellOpts.fail" do
      allow(::ShellOpts).to receive(:fail)
      fail("Message")
    end
  end
end
