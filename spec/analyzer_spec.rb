
include ShellOpts

describe "ShellOpts" do
  def compile(source)
    oneline = source.index("\n").nil?
    tokens = Lexer.lex("main", source, oneline)
    ast = Parser.parse tokens
    grammar = Analyzer.analyze(ast)
  end

  # :call-seq:
  #   names(grammar)
  #   names(source)
  #
  def names(arg) 
    grammar = arg.is_a?(Grammar::Node) ? arg : compile(arg)
    grammar.children.map { |child|
      case child
        when Grammar::OptionGroup; child.options.first.name
        when Grammar::IdrNode; child.name
        else child.token.source
      end
    }
  end

  describe "Grammar" do
    describe "Command" do
    end
  end

  describe "Analyzer" do
    describe "#analyze" do
      it "rejects duplicate options" do
        expect { compile("-a -a") }.to raise_error AnalyzerError
      end
      it "rejects --with-separator together with --with_separator" do
        expect { compile("--with-separator --with_separator") }.to raise_error AnalyzerError
      end
    end

    describe "#reorder_options" do
      it "moves options before the first command" do
        src = %(
          -a
          cmd!
          -b
        )
        expect(names(src)).to eq %w(-a -b cmd)
      end
      it "moves options before the COMMAND section if present" do
        src = %(
          -a
          COMMAND
          cmd!
          -b
        )
        expect(names(src)).to eq %w(-a -b COMMAND cmd)
      end
    end

    describe "#link_commands" do
      it "links subcommands to supercommands" do
        src = %(
          cmd1!
          cmd1.cmd11!
        )
        grammar = compile(src)
        expect(names(grammar)).to eq %w(cmd1 cmd11)
        expect(grammar.commands.size == 1)
        cmd1, cmd11 = grammar.children
        expect(cmd1.name).to eq "cmd1"
        expect(cmd1.commands).to eq [cmd11]
        expect(cmd11.name).to eq "cmd11"
        expect(cmd11.command).to eq cmd1
      end
      it "keeps documentation order" do
        src = %(
          cmd1!
          cmd1.cmd11!
        )
        expect(names(src)).to eq %w(cmd1 cmd11)
      end
      it "handles non-existing supercommands" do
        src = %(
          cmd1.cmd11!
        )
        expect(names(src)).to eq %w(cmd11)
        prog = compile(src)
        cmd11 = prog.commands.first
        expect { compile(src) }.not_to raise_error
      end
    end
  end
end
