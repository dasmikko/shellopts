require 'spec_helper.rb'

require 'shellopts'

module ShellOpts::Ast
  describe Option do
    def parseopt(usage, argv)
      grammar = ShellOpts::Grammar.compile("program", usage)
      ShellOpts::Ast.parse(grammar, argv).options.first
    end

    let(:opt) { parseopt("a", %w(-a)) }
    let(:optval) { parseopt("a=", %w(-aval)) }
    let(:optnval) { parseopt("a=?", %w(-a)) }
    let(:longopt) { parseopt("ab", %w(--ab)) }
    let(:longoptval) { parseopt("ab=", %w(--ab=val)) }
    let(:longoptnval) { parseopt("ab=?", %w(--ab)) }

    describe "#grammar" do
      it "returns the associated Grammar::Node object" do
        grammar = ShellOpts::Grammar.compile("program", "a")
        ast = ShellOpts::Ast.parse(grammar, %w(-a))
        opt = ast.options.find { |opt| opt.name == "-a" }
        expect(opt.grammar).to eq grammar.options["-a"]
      end
    end

    describe "#key" do
      it "is a short-hand for grammar.key" do
        expect(opt.key).to eq opt.grammar.key
      end
    end

    describe "#name" do
      it "includes the prefixed dash(es)" do
        expect(opt.name).to eq "-a"
        expect(longopt.name).to eq "--ab"
      end
    end

    describe "#to_tuple" do
      it "returns a [name, value] tuple" do
        expect(opt.to_tuple).to eq ["-a", nil]
        expect(optval.to_tuple).to eq ["-a", "val"]
        expect(optnval.to_tuple).to eq ["-a", nil ]
      end
    end

    describe "#values" do
      it "returns #value" do
        expect(opt.value).to eq nil
        expect(optval.value).to eq "val"
        expect(optnval.value).to eq nil
      end
    end

    describe "#value" do
      it "is a String, Integer, Float, or nil" do
        sopt = parseopt("a=", %w(-astr))
        iopt = parseopt("a=#", %w(-a42))
        fopt = parseopt("a=$", %w(-a42.21))
        expect(opt.value).to eq nil
        expect(sopt.value).to be_a String
        expect(iopt.value).to be_a Integer
        expect(fopt.value).to be_a Float
        expect(optnval.value).to eq nil
      end
    end
  end
end
