
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
      it "returns the associated option object" do
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

  describe "Generic #<option> and #<option>? methods" do
    let(:spec) { "" }
    let(:argv) { [] }
    let(:opts) { 
      opts, args = ShellOpts::ShellOpts.process(spec, argv)
      opts
    }

    context "when the option is not repeatable" do
      context "when the option doesn't take an argument" do
        let(:spec) { "-a -b" }
        let(:argv) { %w(-a) }
        it "#<option>? returns true iff present" do
          expect(opts.a?).to eq true
          expect(opts.b?).to eq false
        end
        it "#<option> returns true iff present" do
          expect(opts.a).to eq true
          expect(opts.b).to eq false
        end
      end
      context "when the option has an optional argument" do
        let(:spec) { "-a=VAR? -b=VAR? -c=VAR?" }
        let(:argv) { %w(-aAVAR -b) }
        it "#<option>? returns true iff present" do
          expect(opts.a?).to eq true
          expect(opts.b?).to eq true
          expect(opts.c?).to eq false
        end
        it "#<option> returns the value if given" do
          expect(opts.a).to eq "AVAR"
        end
        it "#<option> returns nil if value is missing" do
          expect(opts.b).to eq nil
        end
        it "#<option> returns nil if option not present" do
          expect(opts.c).to eq nil
        end
      end
      context "when the option has a mandatory argument" do
        let(:spec) { "-a=VAR -b=VAR" }
        let(:argv) { %w(-aAVAR) }
        it "#<option>? returns true iff present" do
          expect(opts.a?).to eq true
          expect(opts.b?).to eq false
        end
        it "#<option> returns the value if option is present" do
          expect(opts.a).to eq "AVAR"
        end
        it "#<option> returns nil if option is not present" do
          expect(opts.b).to eq nil
        end
      end
    end

    context "when the option is repeatable" do
      context "when the option doesn't take an argument" do
        let(:spec) { "+a +b +c" }
        let(:argv) { %w(-a -b -b) }
        it "#<option>? returns true iff present" do
          expect(opts.a?).to eq true
          expect(opts.b?).to eq true
          expect(opts.c?).to eq false
        end
        it "#<option> returns count of occurrences" do
          expect(opts.a).to eq 1
          expect(opts.b).to eq 2
          expect(opts.c).to eq 0
        end
      end
      context "when the option has an optional argument" do
        let(:spec) { "+a=VAR? +b=VAR? +c=VAR? +d=VAR? +e=VAR?" }
        let(:argv) { %w(-aAVAR -bBVAR1 -bBVAR2 -c -d -d) }
        it "#<option>? returns true iff present" do
          expect(opts.a?).to eq true
          expect(opts.b?).to eq true
          expect(opts.c?).to eq true
          expect(opts.d?).to eq true
          expect(opts.e?).to eq false
        end
        context "when the option is present" do
          it "#<option> returns an array of values or nil if missing" do
            expect(opts.a).to eq %w(AVAR)
            expect(opts.b).to eq %w(BVAR1 BVAR2)
            expect(opts.c).to eq [nil]
            expect(opts.d).to eq [nil, nil]
          end
        end
        context "when the option is not present" do
          it "#<option> returns the empty array" do
            expect(opts.e).to eq []
          end
        end
      end
      context "when the option has a mandatory argument" do
        let(:spec) { "+a=VAR +b=VAR +c=VAR" }
        let(:argv) { %w(-aAVAR -bBVAR1 -bBVAR2) }
        it "#<option>? returns true iff present" do
          expect(opts.a?).to eq true
          expect(opts.b?).to eq true
          expect(opts.c?).to eq false
        end
        context "when the option is present" do
          it "#<option> returns an array of values" do
            expect(opts.a).to eq %w(AVAR)
            expect(opts.b).to eq %w(BVAR1 BVAR2)
          end
        end
        context "when the option is not present" do
          it "#<option> returns the empty array" do
            expect(opts.c).to eq []
          end
        end
      end
    end
  end

  describe "#subcommand!" do
    it "returns the subcommand object"
  end

  describe "#to_h" do
    let(:opts) { 
      spec = "-a -b=VAL -c"
      argv = %w(-a -bvalue)
      opts, args = ShellOpts::ShellOpts.process(spec, argv)
      opts
    }

    it "returns the used options and their values as a hash" do
      expect(opts.to_h).to eq a: true, b: "value"
    end
    context "when given a list of options" do
      it "returns the given options as a hash" do
        expect(opts.to_h :a).to eq a: true
      end
      it "ignores missing options" do
        expect(opts.to_h :a, :b, :c).to eq a: true, b: "value"
      end
    end
  end
end
