require 'spec_helper.rb'

require 'shellopts/args.rb'

class Messenger
  attr_reader :message
  def error(*msgs) @message = msgs.join end
  def fail(*msgs) @message = msgs.join end
end

class ShellOpts::ShellOpts
  attr_reader :messenger
  def initialize(messenger)
    @messenger = messenger
  end
end

include ShellOpts

describe ShellOpts::Args do
  let(:messenger) { Messenger.new }
  let(:shellopts) { ShellOpts::ShellOpts.new(messenger) }
  let(:args) { Args.new(shellopts, [1, 2, 3, 4, 5]) }

  describe "#extract" do
    it "shifts elements from the beginning of the array" do
      expect(args.extract(2)).to eq [1, 2]
      expect(args).to eq [3, 4, 5]
    end

    it "shifts elements from the end of the array if count is negative" do
      expect(args.extract(-2)).to eq [4, 5]
      expect(args).to eq [1, 2, 3]
    end

    it "expects at least count elements" do
      expect(messenger).to receive(:error)
      args.extract(10)
    end

    it "emits a custom message if given" do
      expect(messenger).to receive(:error).with("Custom")
      args.extract(10, "Custom")
    end
  end

  describe "#expect" do
    it "returns the elements of the array" do
      expect(args.expect(5)).to eq [1, 2, 3, 4, 5]
    end
    it "expects exactly count elements" do
      expect(messenger).to receive(:error)
      args.expect(4)
      expect(messenger).to receive(:error)
      args.expect(6)
    end
    it "emits a custom message if given" do
      expect(messenger).to receive(:error).with("Custom")
      args.expect(10, "Custom")
    end
  end
end








