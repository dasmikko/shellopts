
include ShellOpts

describe "Formatter" do
  describe "::wrap_indent" do
    it "returns a tuple of string and length of last line" do
      l = %w(abc)
      expect(Formatter.wrap_indent(l)).to eq ["abc", 3]
    end
    it "wrap_indents lines to maximum width" do
      l = %w(a b c d e f)
      expect(Formatter.wrap_indent(l, 3).first).to eq "a b\nc d\ne f"
    end
    it "handles words larger than maximum width" do
      l = %w(a bcde f)
      expect(Formatter.wrap_indent(l, 3).first).to eq "a\nbcde\nf"
    end
    it "indents the lines if :indent is > 0" do
      l = %w(a b c d e f)
      expect(Formatter.wrap_indent(l, 5, indent: 2).first).to eq "a b c\n  d e\n  f"
    end
    it "shortens the first line if :initial > 0" do
      l = %w(a b c d e f)
      expect(Formatter.wrap_indent(l, 3, initial: 1).first).to eq "a\nb c\nd e\nf"
    end
  end

  describe "#usage_string" do
    def usage(spec, **opts)
      name = "main"
      tokens = Lexer.lex(name, spec)
      ast = Parser.parse(tokens)
      idr = Analyzer.analyze(ast) # @idr and @ast refer to the same object
      "Usage: #{Formatter.usage_string(idr, **opts)}\n"
    end

    it "returns a short-form usage string for the program" do
      s = "-a -b -- ARG1 ARG2 ARG3 cmd1! cmd2! cmd3!"
      expect(usage(s)).to eq "Usage: main -a -b [cmd1|cmd2|cmd3] ARG1 ARG2 ARG3\n"
    end
    it "wraps options" do
      s = "-a -b -c -d -e"
      expect(usage(s, width: 17)).to eq undent %(
        Usage: main -a -b
                    -c -d
                    -e
      )
    end
    it "brackets commands" do
      s = "cmd1! cmd2!" 
      expect(usage(s)).to eq undent %(
        Usage: main [cmd1|cmd2]
      )
    end
    it "uses the '<commands>' if commands overflows the line" do
      s = "cmd1! cmd2!" 
      expect(usage(s, width: 17)).to eq undent %(
        Usage: main <commands>
      )
    end
    it "wraps splits on options/command-or-arguments boundary" do
      s = "-a -b -c cmd!"
      expect(usage(s, width: 17)).to eq undent %(
        Usage: main -a -b
                    -c
                    [cmd]
      )
    end
    it "wraps splits on options/command-or-arguments boundary" do
      s = "-a -b -c -- ARG"
      expect(usage(s, width: 17)).to eq undent %(
        Usage: main -a -b
                    -c
                    ARG
      )
    end
  end
end
