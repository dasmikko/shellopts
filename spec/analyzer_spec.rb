
include ShellOpts

describe "ShellOpts" do
  def prog(source)
    oneline = source.index("\n").nil?
    tokens = Lexer.lex("main", source, oneline)
    ast = Parser.parse tokens
    grammar = Analyzer.analyze(ast)
  end

  def names(source) 
    prog(source).children.map { |child|
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
        expect { prog("-a -a") }.to raise_error AnalyzerError
      end
      it "rejects --with-separator together with --with_separator" do
        expect { prog("--with-separator --with_separator") }.to raise_error AnalyzerError
      end
    end

    describe "reorder_options" do
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


  end
end
