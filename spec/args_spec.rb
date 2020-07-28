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
  let(:args1) { Args.new(shellopts, [1]) }
  let(:args2) { Args.new(shellopts, [1, 2]) }

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
    context "when given a count" do
      it "expects exactly count elements" do
        expect(messenger).to receive(:error).exactly(2).times
        args.expect(4)
        args.expect(6)
      end
      it "returns an object if count is 1" do
        expect(args1.expect(1)).to eq 1
      end
      it "returns an array if count is greater than 1" do
        expect(args2.expect(2)).to eq [1, 2]
      end
    end
    context "when given a range" do
      it "expects the range to include the number of elements" do
        expect(messenger).to receive(:error).exactly(2).times
        args.expect(0..4)
        args.expect(6..10)
      end
      it "always returns an array" do
        expect(args1.expect(0...1)).to eq [1]
        expect(args2.expect(0...2)).to eq [1, 2]
      end
    end
    it "emits a custom message if given" do
      expect(messenger).to receive(:error).with("Custom")
      args.expect(10, "Custom")
    end
  end
end








