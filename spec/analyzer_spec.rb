
include ShellOpts

describe "ShellOpts" do
  def prog(source)
    oneline = source.index("\n").nil?
    tokens = Lexer.lex("main", source, oneline)
    ast = Parser.parse tokens
    grammar = Analyzer.analyze(ast)
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
  end
end
