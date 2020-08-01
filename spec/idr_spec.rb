require 'spec_helper.rb'

require 'shellopts/generator.rb'

include ShellOpts

describe Idr do
  describe Idr::Node do
    describe "#parent" do
      it "references the parent node" do
        idr = make_idr("A! A.B!", "A B")
        expect(idr.parent).to be nil
        expect(idr.subcommand.parent).to be idr
        expect(idr.subcommand.subcommand.parent).to be idr.subcommand
      end
      it "is null for the top-level Program object" do
        idr = make_idr("A!", "A")
        expect(idr.parent).to eq nil
      end
    end
    describe "#program" do
      it "references the top-level Program object" do
        idr = make_idr("A! A.B!", "A B")
        expect(idr.program).to be idr
        expect(idr.subcommand.program).to be idr
        expect(idr.subcommand.subcommand.program).to be idr
      end
    end
  end

  describe Idr::SimpleOption do
  end

  describe Idr::OptionGroup do
    describe "#names" do
      it "is an array of names of the options" do
        idr = make_idr("+a,all,really-all b", "--really-all -a -b --all")
        expect(idr.options[:all].names).to eq %w(--really-all -a --all)
      end
    end
    describe "#values" do
      it "is an array of values of the options" do
        idr = make_idr("+a +b= +c=?", "-a -a -b ARG1 -b ARG2 -cARG3 -c")
        expect(idr.options[:a].values).to eq [true, true]
        expect(idr.options[:b].values).to eq ["ARG1", "ARG2"]
        expect(idr.options[:c].values).to eq ["ARG3", nil]
      end
    end
    describe "value" do
      it "is redefined to #values" do
        opt = make_idr("+a", "-a -a").options.values.first
        expect(opt.value).to be opt.values
      end
    end
  end

  describe Idr::Command do
    describe "#value" do
      it "is equal to self" do
        idr = make_idr("A!", "A")
        expect(idr.value).to be idr
        expect(idr.subcommand.value).to be idr.subcommand
      end
    end
    describe "#options" do
      it "is indexed by keys" do
        idr = make_idr("a,all", "-a")
        expect(idr.options[:all]).to be idr.option_list.first
        expect(idr.options["--all"]).to eq nil
      end
      it "groups repeated options into a OptionGroup object" do
        idr = make_idr("+a", "-a -a")
        expect(idr.options[:a]).to be_a Idr::OptionGroup
      end
      it "set the name of the option group to Grammar::Option#key_name" do
        idr = make_idr("+a,all", "-a -a")
        expect(idr.options[:all].name).to eq "--all"
      end
      it "includes the subcommand" do
        idr = make_idr("C!", "C")
        expect(idr.options[:C!]).to be_a Idr::Command
      end
    end
    describe "#option_list" do
      it "is a list of Option objects" do
        idr = make_idr("a b", "-a -b")
        expect(idr.option_list).to all(be_an(Idr::Option))
      end
    end
    describe "#subcommand" do
      it "is Command object or nil" do
        idr = make_idr("A!", "A")
        expect(idr.subcommand).to be_a Idr::Command
        idr = make_idr("A!", "")
        expect(idr.subcommand).to eq nil
      end
    end
    describe "#declared?" do
      it "accepts both names and keys" do
        idr = make_idr("a", "")
        expect(idr.declared?(:a)).to eq true
        expect(idr.declared?("-a")).to eq true
      end
      it "accepts any synonymon for an option" do
        idr = make_idr("a,all", "")
        expect(idr.declared?("-a")).to eq true
        expect(idr.declared?("--all")).to eq true
      end
      it "returns true if option or command is declared" do
        idr = make_idr("a b", "-a")
        expect(idr.declared?(:a)).to eq true
        expect(idr.declared?(:b)).to eq true
        expect(idr.declared?(:c)).to eq false
      end
    end
    describe "#option?" do
      it "returns true if ident is declared as an option" do
        idr = make_idr("a C!", "")
        expect(idr.option?(:a)).to eq true
        expect(idr.option?(:b)).to eq false
        expect(idr.option?(:C!)).to eq false
      end
    end
    describe "command?" do
      it "returns true if ident is declared as a command" do
        idr = make_idr("a C!", "")
        expect(idr.subcommand?(:a)).to eq false
        expect(idr.subcommand?(:C!)).to eq true
        expect(idr.subcommand?(:D!)).to eq false
      end
    end
    describe "#key?" do
      it "accepts both names and keys" do
        idr = make_idr("a", "-a")
        expect(idr.key?(:a)).to eq true
        expect(idr.key?("-a")).to eq true
      end
      it "accepts any synonymon for an option" do
        idr = make_idr("a,all", "-a")
        expect(idr.key?("-a")).to eq true
        expect(idr.key?("--all")).to eq true
      end
      it "returns true if key or name is present" do
        idr = make_idr("a b", "-a")
        expect(idr.key?("-a")).to eq true
        expect(idr.key?("-b")).to eq false
      end
      it "reports on both options and commands" do
        idr = make_idr("a A!", "-a A")
        expect(idr.key?(:a)).to eq true
        expect(idr.key?(:A!)).to eq true
      end
    end
    describe "#[]" do
      it "accepts both names and keys" do
        idr = make_idr("a", "-a")
        expect(idr[:a]).to eq true
        expect(idr["-a"]).to eq true
      end
      it "accepts any synonymon for an option" do
        idr = make_idr("a,all b,ball", "-a")
        expect(idr.key?("-a")).to eq true
        expect(idr.key?("--all")).to eq true
      end
      it "returns the value of the option or command" do
        idr = make_idr("a= A!", "-a ARG A")
        expect(idr[:a]).to eq "ARG"
        expect(idr[:A!]).to eq idr.subcommand
      end
      it "returns true for options that can't be parametrized" do
        idr = make_idr("a b", "-a")
        expect(idr[:a]).to eq true
      end
      it "returns false for unused options" do
        idr = make_idr("a b", "-a")
        expect(idr[:b]).to eq false
      end
      it "returns nil for missing optional parameters" do
        idr = make_idr("a=? b=", "-a -bARG")
        expect(idr[:a]).to eq nil
        expect(idr[:b]).to eq "ARG"
      end
      it "returns an array of values for repeated options" do
        idr = make_idr("+a +b= +c=?", "-a -a -b ARG1 -b ARG2 -cARG3 -c" )
        expect(idr[:a]).to eq [true, true]
        expect(idr[:b]).to eq ["ARG1", "ARG2"]
        expect(idr[:c]).to eq ["ARG3", nil]
      end
      it "returns nil for an unused command" do
        idr = make_idr("A! B!", "A")
        expect(idr[:A!]).to eq idr.subcommand
        expect(idr[:B!]).to eq nil
      end
      it "raises on a non-existing option or command" do
        idr = make_idr("a A!", "-a A")
        expect { idr[:b] }.to raise_error InternalError
        expect { idr[:B!] }.to raise_error InternalError
      end
    end
    describe "#to_h" do
      it "returns a hash of the Idr" do
        idr = make_idr("a", "")
        expect(idr.to_h).to eq({})
      end
      it "adds a #subcommand method to the hash" do
        h = make_idr("C!", "C").to_h
        expect(h).to respond_to(:subcommand)
        expect(h.subcommand).to eq :C
        h = make_idr("C!", "").to_h
        expect(h.subcommand).to eq nil
      end
      it "uses unique keys when key type is :key" do
        h = make_idr("a C!", "-a C").to_h(key_type: :key)
        expect(h).to eq({:a => true, :C! => {}})
        expect(h.subcommand).to eq :C!
      end
      it "renames keys using +aliases+" do
        h = make_idr("a C!", "-a C").to_h(aliases: { a: :all, C!: :command })
        expect(h).to eq({:all => true, :command => {}})
        expect(h.subcommand).to eq :command
      end
      it "commands are nested hashes" do
        idr = make_idr("a C! b", "-a C -b")
        expect(idr.to_h).to eq({:a => true, :C => { :b => true }})
      end
    end
  end

  describe Idr::Program do
    describe "#key" do
      idr = make_idr("a", "-a")
      it "is nil" do
        expect(idr.key).to eq nil
      end
    end
    describe "#name" do
      it "is the name of the program" do
        idr = make_idr("a", "-a")
        expect(idr.name).to eq "rspec"
      end
    end
  end
end
