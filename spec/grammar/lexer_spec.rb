
include ShellOpts
include ShellOpts::Grammar

describe ShellOpts::Grammar::Lexer do
  def lex(src) Lexer.lex(src) end

  describe "::lex" do
    it "returns an array of [type, src] tuples" do
      src = "-a"
      expect(lex(src)).to eq [["OPT", "-a"]]
      src = "cmd!"
      expect(lex(src)).to eq [["CMD", "cmd!"]]
    end
    it "breaks a source line into command, options, and arguments" do
      src = "cmd! -a ARG"
      expect(lex(src)).to eq [["CMD", "cmd!"], ["OPT", "-a"], ["ARG", "ARG"]]
    end
    it "recognizes commands after args" do
      src = "cmd1! ARG1 cmd2! ARG2"
      expect(lex(src)).to eq [["CMD", "cmd1!"], ["ARG", "ARG1"], ["CMD", "cmd2!"], ["ARG", "ARG2"]]
    end
    it "recognizes the end-of-arguments marker" do
      src = "-a -- ARG"
      expect(lex(src)).to eq [["OPT", "-a"], ["ARG", "ARG"]]
    end
    it "accepts no options and no commands" do
      src = "ARG"
      expect(lex(src)).to eq [["ARG", "ARG"]]
    end
    it "returns multiple arguments as one" do
      src = "cmd! -a ARG1 ARG2"
      expect(lex(src)).to eq [["CMD", "cmd!"], ["OPT", "-a"], ["ARG", "ARG1 ARG2"]]
    end
    it "recognizes comments" do
      src = "cmd!\nThis is a comment"
      expect(lex(src)).to eq [["CMD", "cmd!"], ["TXT", "This is a comment"]]
    end
    it "moves comments to just after the first command/option" do
      src = "cmd! -a\nThis is a comment"
      expect(lex(src)).to eq [["CMD", "cmd!"], ["TXT", "This is a comment"], ["OPT", "-a"]]
    end
    it "raises on illegal short option names" do
      src = "-ab"
      expect { lex(src) }.to raise_error CompileError, "Illegal short option name: -ab"
      src = "-n,name=NAME"
      expect { lex(src) }.not_to raise_error
    end
    it "raises on illegal syntax" do
      src = "cmd! arg"
      expect { lex(src) }.to raise_error CompileError, "Illegal argument: arg (should be uppercase)"
    end
  end
end
