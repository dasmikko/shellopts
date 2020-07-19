
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

  describe "#[]" do
    it "returns true if option is present" do
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
    it "returns nil if the option isn't present" do
      hash = process2("a", %w(-a))
      expect(hash["-b"]).to eq nil
    end
    it "accepts option aliases" do
      hash = process2("a,all", %w(-a))
      expect(hash["--all"]).to eq true
    end
    it "accepts commands" do
      hash = process2("A! B!", %w(A))
      expect(hash["A"]).to be_a Hash # Oops
      expect(hash["B"]).to eq nil
    end
    it "nests command options under the command hash" do
      hash = process2("A! a", %w(A -a))
      expect(hash["A"]["-a"]).to be true
    end
  end



# it "returns an array of arguments for repeated options with arguments"
# it "returns nil


  
end

