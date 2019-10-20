require 'spec_helper.rb'

require 'shellopts'

module ShellOpts::Grammar
  describe Option do
    def opt_w_flags(*flags)
      Option.new(%w(-a), %w(--all), flags)
    end

    let(:opt) { Option.new(%w(-a), [], {}) }
    let(:optalias) { Option.new(%w(-a), %w(--ab), {}) }

    describe "#initialize" do
      it "initializes Node#key" do
        expect(opt.key).to eq :a
        expect(optalias.key).to eq :ab
      end
    end

    describe "#key" do
      it "uses the name of the first long option if present" do
        expect(optalias.key).to eq :ab
      end
      it "doesn't include the prefixed dash(es)" do
        expect(opt.key).to eq :a
      end
    end

    describe "#names" do
      it "returns an array of short names concatenated with long names" do
        expect(optalias.names).to eq %w(-a --ab)
      end
    end


# HER



    describe "#repeated?" do
      it "returns true iff the :repeated flag is present" do
        expect(opt_w_flags(:repeated).repeated?).to be true
        expect(opt_w_flags().repeated?).to be false
      end
    end

    describe "#argument?" do
      it "returns true iff the :argument flag is present" do
        expect(opt_w_flags(:argument).argument?).to be true
        expect(opt_w_flags().argument?).to be false
      end
    end

    describe "#optional?" do
      it "returns true iff the :argument and :optional flags is present" do
        expect(opt_w_flags(:argument, :optional).optional?).to be true
        expect(opt_w_flags(:optional).optional?).to be false
        expect(opt_w_flags().optional?).to be false
      end
    end

    describe "#string?" do
      it "returns true iff the :argument flag is present but not :integer or :float" do
        expect(opt_w_flags(:argument).string?).to be true
        expect(opt_w_flags(:argument, :integer).string?).to be false
        expect(opt_w_flags(:argument, :float).string?).to be false
        expect(opt_w_flags().string?).to be false
      end
    end

    describe "#integer?" do
      it "returns true iff the :argument and :integer flags are present" do
        expect(opt_w_flags(:argument, :integer).integer?).to be true
        expect(opt_w_flags(:integer).integer?).to be false
        expect(opt_w_flags().integer?).to be false
      end
    end

    describe "#float?" do
      it "returns true iff the :argument and :float flags are present" do
        expect(opt_w_flags(:argument, :float).float?).to be true
        expect(opt_w_flags(:float).float?).to be false
        expect(opt_w_flags().float?).to be false
      end
    end
  end
end

