
include ShellOpts

describe "Formatter" do
  def parse(src)
    exprs = Grammar::Lexer.lex(src)
    commands = Grammar::Parser.parse("rspec", exprs)
    grammar = Grammar::Analyzer.analyze(commands)
  end

  describe "::usage_string" do
    it "returns a usage string" do
      src = "-a,all ARG"
      grammar = parse(src)
      expect(Formatter.usage_string(grammar)).to eq "rspec -a ARG"
    end
    context "when the command has sub-commands" do
      it "concatenates the sub-commands with a '|'" do
        src = "-a,all cmd1! ARG1 cmd2! ARG2"
        grammar = parse(src)
        expect(Formatter.usage_string(grammar)).to eq "rspec -a cmd1|cmd2"
      end
    end
    context "when level > 1" do
      it "expands the given level of sub-commands" do
        src = "-a,all cmd1! ARG1 cmd2! ARG2"
        grammar = parse(src)
        expect(Formatter.usage_string(grammar, levels: 2)).to eq "rspec cmd1 ARG1\nrspec cmd2 ARG2"
      end
    end

    context "when the argument is a sub-command" do
      it "returns the usage string for that sub-command" do
        src = "-a,all cmd1! ARG1 cmd2! ARG2"
        grammar = parse(src)
        cmd = grammar.commands["cmd1"]
        expect(Formatter.usage_string(cmd)).to eq "rspec cmd1 ARG1"
      end
    end
    context "when the argument is a virtual sub-command" do
      it "returns the usage_string for each sub-command of the virtual sub-command" do
        src = "-a,all cmd1.cmd11! -c ARG11 cmd1.cmd12! -d ARG12"
        grammar = parse(src)
        cmd = grammar.commands["cmd1"]
        expect(Formatter.usage_string(cmd)).to eq "rspec cmd1 cmd11 -c ARG11\nrspec cmd1 cmd12 -d ARG12"
      end
    end
  end

  describe "::help_string" do
    it "returns an array of [usage_string, help_string, option-descriptions] triplets" do
      src = "-a,all\ncmd1! ARG1\ncmd1 descr\nmore descr\n-a,all\nAll\ncmd2! ARG2\ncmd2 descr"
      grammar = parse(src)
      cmd = grammar.commands["cmd1"]
      expect(Formatter.help_string(cmd)).to eq \
          "rspec cmd1 -a ARG1\n  cmd1 descr\n  more descr\n\n  -a, --all\n    All"
    end
    it "formats option arguments too" do
      src = "-a,all\ncmd1! ARG1\ncmd1 descr\nmore descr\n-a,arg=ARG\nArg descr"
      grammar = parse(src)
      cmd = grammar.commands["cmd1"]
      cmd = grammar.commands["cmd1"]
      expect(Formatter.help_string(cmd)).to eq \
          "rspec cmd1 -a ARG ARG1\n  cmd1 descr\n  more descr\n\n  -a, --arg=ARG\n    Arg descr"
    end
  end
end

