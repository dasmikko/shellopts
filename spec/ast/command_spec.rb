require 'spec_helper.rb'

require 'shellopts'

module ShellOpts::Ast
  describe Command do
    def parsecmd(usage, argv)
      grammar = ShellOpts::Grammar.compile("program", usage)
      ShellOpts::Ast.parse(grammar, argv).subcommand
    end

    let(:cmd) { parsecmd("cmd!", %w(cmd)) }
    let(:cmdopt) { parsecmd("cmd! a", %w(cmd -a)) }
    let(:cmdopts) { parsecmd("cmd! a b c", %w(cmd -a -b -c)) }
    let(:cmdoptcmd) { parsecmd("cmd1! a cmd1.cmd2!", %w(cmd1 -a cmd2)) }

    describe "#grammar" do
      it "returns the associated Grammar::Node object" do
        grammar = ShellOpts::Grammar.compile("program", "cmd!")
        ast = ShellOpts::Ast.parse(grammar, %w(cmd))
        expect(ast.subcommand.grammar).to eq grammar.subcommands["cmd"]
      end
    end

    describe "#key" do
      it "is a short-hand for grammar.key" do
        expect(cmd.key).to eq cmd.grammar.key
      end
    end

    describe "#name" do
      it "doesn't include the suffixed exclamation point" do
        expect(cmd.name).to eq "cmd"
      end
    end

    describe "#to_tuple" do
      it "returns a [name, value] tuple" do
        expect(cmd.to_tuple).to eq ["cmd", []]
        expect(cmdopt.to_tuple).to eq ["cmd", [["-a", nil]]]
      end
    end

    describe "#values" do
      it "is an array of options and command tuples" do
        expect(cmdopt.values).to eq [["-a", nil]]
        expect(cmdoptcmd.values).to eq [["-a", nil], ["cmd2", []]]
      end
    end

    describe "#options" do
      it "is an array of options" do
        expect(cmdopts.options.map(&:name)).to eq %w(-a -b -c)
      end
    end

    describe "#command" do
      it "is an optional sub-command" do
        expect(cmdopt.subcommand).to eq nil
        expect(cmdoptcmd.subcommand.name).to eq "cmd2"
      end
    end
  end
end


