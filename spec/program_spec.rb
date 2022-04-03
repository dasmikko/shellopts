
include ShellOpts

describe "Command" do
  describe "#key?" do
    let(:opts) { 
      spec = "-a -b cmd1! cmd2!"
      argv = %w(-a cmd1)
      opts, args = ShellOpts::ShellOpts.process(spec, argv)
      opts
    }

    it "returns true if the key matches an object" do
      expect(opts.key?(:a)).to eq true
      expect(opts.key?(:b)).to eq false
      expect(opts.key?(:cmd1!)).to eq true
      expect(opts.key?(:cmd2!)).to eq false
    end
    it "raises if identifier doesn't match" do
      expect { opts.key?(:not_there) }.to raise_error ArgumentError 
    end
  end
  describe "#[]" do
    let(:opts) { 
      spec = "-a -b +c=IDX +d cmd1! cmd2!"
      argv = %w(-a -c1 -c2 cmd1)
      opts, args = ShellOpts::ShellOpts.process(spec, argv)
      opts
    }

    context "when the key is an option" do
      it "returns the associated option" do
        expect(opts[:a]).to be_a ShellOpts::Option
      end
      it "returns nil if the option wasn't present" do
        expect(opts[:b]).to eq nil
      end
      context "when the option is repeatable" do
        it "returns a list of options" do
          expect(opts[:c].map(&:class)).to eq [ShellOpts::Option, ShellOpts::Option]
          expect(opts[:c].map(&:argument)).to eq ["1", "2"]
        end
        it "returns an empty array if the option wasn't present" do
          expect(opts[:d]).to eq []
        end
      end
    end
    context "when the key is a command" do
      it "returns the associated command" do
        expect(opts[:cmd1!].is_a?(ShellOpts::Command)).to eq true
      end
      it "returns nil if the option wasn't present" do
        expect(opts[:cmd2!]).to eq nil
      end
    end
    it "raises if the key doesn't exist" do
      expect { opts[:e] }.to raise_error ArgumentError
      expect { opts[:cmd3!] }.to raise_error ArgumentError
    end
  end
  describe "::to_h" do
    let(:opts) { 
      spec = "-a -b=VAL -c"
      argv = %w(-a -bvalue)
      opts, args = ShellOpts::ShellOpts.process(spec, argv)
      opts
    }

    it "returns the used options as a hash" do
      expect(opts.to_h).to eq a: nil, b: "value"
    end
    context "when given a list of options" do
      it "returns the given options as a hash" do
        expect(opts.to_h :a).to eq a: nil
      end
      it "ignores missing options" do
        expect(opts.to_h :a, :b, :c).to eq a: nil, b: "value"
      end
    end
  end
end
