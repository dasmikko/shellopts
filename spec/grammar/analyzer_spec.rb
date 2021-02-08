
include ShellOpts # Needed for unqualified exceptions
include ShellOpts::Grammar

describe ShellOpts do
  describe Analyzer do
    def build_commands(spec)
      exprs = Lexer.lex(spec)
      commands = Parser.parse("rspec", exprs)
      program = Analyzer.analyze(commands)
      commands
    end

    def build_program(spec)
      build_commands.first
    end

    describe "::analyze" do
      it "fails on duplicate option names in groups" do
        src = "-a,a"
        expect { build_commands(src) }.to \
            raise_error CompileError, "Duplicate option name 'a'"
      end
      it "fails on duplicate option names in commands" do
        src = "-a -a"
        expect { build_commands(src) }.to \
            raise_error CompileError, "Duplicate option name 'a'"
      end
      it "fails on duplicate option identifers" do
        src = "--a_b --a-b"
        expect { build_commands(src) }.to \
            raise_error CompileError, "Duplicate option identifier 'a_b'"
      end
      it "fails on duplicate command names" do
        src = "a! a!"
        expect { build_commands(src) }.to \
            raise_error CompileError, "Duplicate command name 'a'"
      end
      it "fails on duplicate command identifiers" do
        src = "a-b! a_b!"
        expect { build_commands(src) }.to \
            raise_error CompileError, "Duplicate command identifier 'a_b'"
      end

      it "links up commands" do
        src = "a! a.b! a.b.c!"
        a, b, c = build_commands(src)
        expect(a.parent.name).to eq "rspec"
        expect(b.parent).to eq a
        expect(c.parent).to eq b
      end

      it "builds Command#options" do
        src = "a! -v -w"
        a = build_commands(src).first
        expect(a.options["v"]).to be_a(Option)
        expect(a.options["w"].name).to eq "w"
      end

      it "builds Command#commands" do
        src = "a! a.b! a.c!"
        a, b, c = build_commands(src)
        expect(a.commands["b"]).to eq b
        expect(a.commands["c"]).to eq c
      end
    end
  end
end
