
require "spec_helper.rb"
require "shellopts/options_hash.rb"

describe ShellOpts::OptionsHash do
  def process2(usage, argv)
    ::ShellOpts.reset
    ::ShellOpts.process2(usage, argv)
  end

  it "is returned from ShellOpts.process2" do
    hash = ShellOpts.process2("a b= c=?", %w(-a -b ARG -c OPT))
    expect(hash).to be_a ::ShellOpts::OptionsHash
  end

  describe "#ast" do
    it "returns the associated Ast object"
  end

  describe "#key" do
    it "returns true iff the option is present" do
      hash = process2("a b", %w(-a))
      expect(hash.key?("-a")).to eq true
      expect(hash.key?("-b")).to eq false
    end
    it "returns true iff the command is present" do
      hash = process2("A! B!", %w(A))
      expect(hash.key?("A")).to eq true
      expect(hash.key?("B")).to eq false
    end
  end

  describe "#[]" do
    it "accepts option names" do
      hash = process2("a", %w(-a))
      expect(hash["-a"]).to eq true
    end
    it "accepts option aliases" do
      hash = process2("a,all", %w(-a))
      expect(hash["--all"]).to eq true
    end
    it "accepts symbolic keys" do
      hash = process2("a,all", %w(-a))
      expect(hash[:all]).to eq true
    end
    it "accepts commands" do
      hash = process2("A! B!", %w(A))
      expect(hash["A"]).not_to eq nil
      expect(hash["B"]).to eq nil
    end
    it "returns nil if not found" do
      hash = process2("a", %w(-a))
      expect(hash["-b"]).to eq nil
    end
    it "returns true if a non-argument option is present" do
      hash = process2("a", %w(-a))
      expect(hash["-a"]).to eq true
    end
    it "returns an array of true values if multiple options are allowed" do
      hash = process2("+a", %w(-a -a))
      expect(hash["-a"]).to eq [true, true]
    end
    it "returns the argument if an argument is required" do
      hash = process2("a=", %w(-a ARG))
      expect(hash["-a"]).to eq "ARG"
    end
    it "returns an array of arguments if multiple options are allowed" do
      hash = process2("+a=", %w(-a ARG1 -a ARG2))
      expect(hash["-a"]).to eq ["ARG1", "ARG2"]
    end
    it "returns a value or nil if the argument is optional" do
      hash = process2("a=? b=?", %w(-aARG -b))
      expect(hash["-a"]).to eq "ARG"
      expect(hash["-b"]).to eq nil
    end
    it "returns an array of values or nil if multiple options are allowed" do
      hash = process2("+a=?", %w(-aARG -a))
      expect(hash["-a"]).to eq ["ARG", nil]
    end
    it "returns a ShellOpts::OptionHash value for commands" do
      hash = process2("A! B!", %w(A))
      expect(hash["A"]).to be_a ::ShellOpts::OptionsHash
    end
    it "nests command options under the command hash" do
      hash = process2("A! a", %w(A -a))
      expect(hash["A"]["-a"]).to be true
    end
  end

  describe "#size" do
    it "returns the number of options and commands" do
      hash = process2("a,all b", %w(-a -b))
      expect(hash.size).to eq 2
      hash = process2("a,all b A!", %w(-a -b A))
      expect(hash.size).to eq 3
    end
  end

  describe "#keys" do
    # TODO Define order of keys
    it "returns an array of the used keys" do
      hash = process2("a,all b", %w(-a -b))
      expect(hash.keys).to eq [:all, :b]
    end
  end

  describe "#values" do
    # TODO Define order of values
    it "returns an array of values" do
      hash = process2("+a,all= b= c=?", %w(-a ARG1 -a ARG2 -b ARG3 -c))
      expect(hash.values).to eq [["ARG1", "ARG2"], "ARG3", nil]
    end
  end

  describe "#name" do
    it "returns the used option alias" do
      hash = process2("a,all b,bee +c,C", %w(-a --bee -c -C))
      expect(hash.name("-a")).to eq "-a"
      expect(hash.name("--all")).to eq "-a"
      expect(hash.name("-b")).to eq "--bee"
      expect(hash.name("--bee")).to eq "--bee"
    end

    it "returns nil if not found" do
      hash = process2("a,all b,bee +c,C", %w(-a --bee -c -C))
      expect(hash.name("-d")).to eq nil
    end

    context "with an index argument" do
      it "returns the name used in that occurence" do
        hash = process2("a,all b,bee +c,C", %w(-a --bee -c -C))
        expect(hash.name("-c", 0)).to eq "-c"
        expect(hash.name("-c", 1)).to eq "-C"
      end
    end
  end

  describe "#node" do
    it "returns the Ast::Node object" do
      hash = process2("a,all +b,bee=", %w(-a -b B --bee=BEE))
      ast = hash.instance_variable_get("@ast")
      expect(hash.node("-a").grammar).to be ast.grammar.options["-a"]
    end

    it "returns nil if not found" do
      hash = process2("a,all +b,bee=", %w(-a -b B --bee=BEE))
      expect(hash.node("-c")).to eq nil
    end

    context "with an index argument" do
      it "returns the node at that index" do
        hash = process2("+b,bee=", %w(-b B --bee=BEE))
        ast = hash.instance_variable_get("@ast")
        node1 = ast.options[0]
        node2 = ast.options[1]
        expect(hash.node("-b", 0)).to be node1
        expect(hash.node("-b", 1)).to be node2
      end
    end
  end
end

