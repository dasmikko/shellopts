
include ShellOpts

def undent(s)
  lines = s.split("\n")
  lines.shift while !lines.empty? && lines.first !~ /^(\s*)(\S+)$/
  return "" if lines.empty?
  indent = $1.size
  r = []
  while line = lines.shift
    r << (line[indent..-1] || "")
  end
  while !r.empty? && r.last =~ /^\s*$/
    r.pop
  end
  r.join("\n") + "\n"
end

describe "Parser" do
  def prog(source)
    Parser.parse(Lexer.lex("main", source))
  end

  def struct(source)
    prog(source).render_structure
  end

  describe "::parse" do
    it "parses !cmd" do
      s = "!cmd"
      expect(struct s).to eq undent %(
        main!
          cmd!
      )
    end
    it "parses -a !cmd" do
      s = "-a !cmd"
      expect(struct s).to eq undent %(
        main!
          -a
          cmd!
      )
    end
    it "parses -a !cmd -b" do
      s = "-a !cmd -b"
      expect(struct s).to eq undent %(
        main!
          -a
          cmd!
            -b
      )
    end
    it "parses -a !cmd -a" do
      s = "-a !cmd -a"
      expect(struct s).to eq undent %(
        main!
          -a
          cmd!
            -a
      )
    end
    it "parses -a !cmd1 -b !cmd2 -c" do
      s = "-a !cmd1 -b !cmd2 -c"
      expect(struct s).to eq undent %(
        main!
          -a
          cmd1!
            -b
          cmd2!
            -c
      )
    end
    it "parses -a !cmd1 -b !cmd1.cmd2 -c" do
      s = "-a !cmd1 -b !cmd1.cmd2 -c"
      expect(struct s).to eq undent %(
        main!
          -a
          cmd1!
            -b
            cmd2!
              -c
      )
    end
    it "parses -a !cmd1 -b !cmd1.cmd2 -c !cmd1.cmd2.cmd3 -d" do
      s = "-a !cmd1 -b !cmd1.cmd2 -c !cmd1.cmd2.cmd3 -d"
      expect(struct s).to eq undent %(
        main!
          -a
          cmd1!
            -b
            cmd2!
              -c
              cmd3!
                -d

      )
    end
    it "parses -- ARG" do
      s = "-- ARG"
      expect(struct s).to eq undent %(
        main!
          ARG
      )
    end
    it "parses -a -- ARG" do
      s = "-a -- ARG"
      expect(struct s).to eq undent %(
        main!
          -a
          ARG
      )
    end
    it "parses -a -- ARG0 !cmd1 -b -- ARG1" do
      s = "-a -- ARG0 !cmd1 -b -- ARG1"
      expect(struct s).to eq undent %(
        main!
          -a
          cmd1!
            -b
            ARG1
          ARG0
      )
    end
    it "parses -a -- ARG0 !cmd1 -b -- ARG1 !cmd2 -c -- ARG2" do
      s = "-a -- ARG0 !cmd1 -b -- ARG1 !cmd2 -c -- ARG2"
      expect(struct s).to eq undent %(
        main!
          -a
          cmd1!
            -b
            ARG1
          cmd2!
            -c
            ARG2
          ARG0
      )
    end
  end

#     spec = "-a -b=something -- ARG1 !cmd -- ARG2" # TODO: Make it possible to say "-a -b ARG1 !cmd ARG2"
#     spec = "-a -b -- ARG1 ARG2 ARG3 ARG4 !cmd1 !cmd2 !cmd3 !cmd4" # FIXME

end

describe "Command#parse" do
  it "sets uid" do
    source = "!cmd1"
    tokens = Lexer.lex("main", source)
    program = Parser.parse(tokens)
    expect(program.uid).to eq nil
    expect(program.path).to eq []
    command = program.commands.first
    expect(command.uid).to eq "cmd1!"
    expect(command.path).to eq [:cmd1!]
  end
end

describe "Option#parse" do
  def opt(source, method = nil)
    tokens = Lexer.lex("main", source)
    program = Parser.parse(tokens)
    option = program.options.first
    method ? option.send(method) : option
  end

  it "accepts -s and +s" do
    expect { opt "-s" }.not_to raise_error
    expect { opt "+s" }.not_to raise_error
  end
  it "accepts --long and ++long" do
    expect { opt "--long" }.not_to raise_error
    expect { opt "++long" }.not_to raise_error
  end
  it "accepts -s,long and +s,long" do
    expect { opt "-s,long" }.not_to raise_error
    expect { opt "+s,long" }.not_to raise_error
  end
  it "accepts --long,more and ++long,more" do
    expect { opt "--long,more" }.not_to raise_error
    expect { opt "++long,more" }.not_to raise_error
  end
  it "rejects --l" do
    expect { opt "--l" }.to raise_error ParserError
  end

  context "sets ident" do
    context "to the name of the option" do
      it "without initial '-' and '--'" do
        expect(opt "-l", :ident).to eq :l
        expect(opt "--long", :ident).to eq :long
      end
      it "with internal '-' replaced with '_'" do
        expect(opt "--with-separator", :ident).to eq :with_separator
        expect(opt "--with_separator", :ident).to eq :with_separator
      end
    end
  end

  context "sets name" do
    it "to the name of the first long option if present" do
      expect(opt "-s,long,more", :name).to eq "--long"
    end
    it "and otherwise to the name of the first short option" do
      expect(opt "-s,t", :name).to eq "-s"
    end
  end

  it "sets short_names" do
    expect(opt "--long", :short_names).to eq []
    expect(opt "-a,b", :short_names).to eq %w(-a -b)
    expect(opt "-a,b,long", :short_names).to eq %w(-a -b)
  end

  it "sets long_names" do
    expect(opt "-a", :long_names).to eq []
    expect(opt "--long,more", :long_names).to eq %w(--long --more)
    expect(opt "-a,long,more", :long_names).to eq %w(--long --more)
  end

  it "sets repeatable?" do
    expect(opt "-v", :repeatable?).to eq false
    expect(opt "+v", :repeatable?).to eq true
  end

  it "sets argument?" do
    expect(opt "-s", :argument?).to eq false
    expect(opt "-s=SOME", :argument?).to eq true
  end

  context "without an argument" do
    it "sets argument_type to the default" do
      expect(opt "-s=SOME", :argument_type).to be_a Grammar::ArgumentType
    end
  end

  context "with an argument" do
    it "fails on missing argument" do
      expect { opt "-s=" }.to raise_error ParserError
    end
    it "accepts non-interpreted arguments" do
      src = "-s=<some-value>"
      expect { opt src }.not_to raise_error
      option = opt src
      expect(option.argument?).to eq true
      expect(option.argument_name).to eq "<some-value>"
      expect(option.argument_type).to be_a Grammar::ArgumentType
    end
    it "sets optional?" do
      expect(opt "-s=SOME", :optional?).to eq false
      expect(opt "-s=SOME?", :optional?).to eq true
    end
    context "without a type specification" do
      it "sets argument_name" do
        expect(opt "-s=SOME", :argument_name).to eq "SOME"
      end
    end
    context "with a '#' type specifier" do
      it "sets argument_type to IntegerArgument" do
        expect(opt "-s=VAL:#", :argument_type).to be_a Grammar::IntegerArgument
        expect(opt "-s=:#", :argument_type).to be_a Grammar::IntegerArgument
        expect(opt "-s=#", :argument_type).to be_a Grammar::IntegerArgument
      end

      it "defaults argument_name to 'INT'" do
        expect(opt "-s=VAL:#", :argument_name).to eq "VAL"
        expect(opt "-s=:#", :argument_name).to eq "INT"
        expect(opt "-s=#", :argument_name).to eq "INT"
      end
    end
    context "with a '$' argument_type specifier" do
      it "sets argument_type to FloatArgument" do
        expect(opt "-s=VAL:$", :argument_type).to be_a Grammar::FloatArgument
        expect(opt "-s=:$", :argument_type).to be_a Grammar::FloatArgument
        expect(opt "-s=$", :argument_type).to be_a Grammar::FloatArgument
      end

      it "defaults argument_name to 'NUM'" do
        expect(opt "-s=VAL:$", :argument_name).to eq "VAL"
        expect(opt "-s=:$", :argument_name).to eq "NUM"
        expect(opt "-s=$", :argument_name).to eq "NUM"
      end
    end
    context "with a keyword specifier" do
      it "sets argument_type to FileArgument" do
        expect(opt "-s=VAL:FILE", :argument_type).to be_a Grammar::FileArgument
        expect(opt "-s=:FILE", :argument_type).to be_a Grammar::FileArgument
        expect(opt "-s=FILE", :argument_type).to be_a Grammar::FileArgument
      end
      it "defaults file or file path argument_name to 'FILE'" do
        expect(opt "-s=VAL:FILE", :argument_name).to eq "VAL"
        expect(opt "-s=:FILE", :argument_name).to eq "FILE"
        expect(opt "-s=FILE", :argument_name).to eq "FILE"
        expect(opt "-s=:EFILE", :argument_name).to eq "FILE"
        expect(opt "-s=EFILE", :argument_name).to eq "FILE"
        expect(opt "-s=:NFILE", :argument_name).to eq "FILE"
        expect(opt "-s=NFILE", :argument_name).to eq "FILE"
      end
      it "defaults directory or directory path argument_name to 'DIR'" do
        expect(opt "-s=VAL:DIR", :argument_name).to eq "VAL"
        expect(opt "-s=:DIR", :argument_name).to eq "DIR"
        expect(opt "-s=DIR", :argument_name).to eq "DIR"
        expect(opt "-s=:EDIR", :argument_name).to eq "DIR"
        expect(opt "-s=EDIR", :argument_name).to eq "DIR"
        expect(opt "-s=:NDIR", :argument_name).to eq "DIR"
        expect(opt "-s=NDIR", :argument_name).to eq "DIR"
      end
      it "defaults path argument_name to 'PATH'" do
        expect(opt "-s=VAL:PATH", :argument_name).to eq "VAL"
        expect(opt "-s=:PATH", :argument_name).to eq "PATH"
        expect(opt "-s=PATH", :argument_name).to eq "PATH"
        expect(opt "-s=:EPATH", :argument_name).to eq "PATH"
        expect(opt "-s=EPATH", :argument_name).to eq "PATH"
        expect(opt "-s=:NPATH", :argument_name).to eq "PATH"
        expect(opt "-s=NPATH", :argument_name).to eq "PATH"
      end
    end
    context "with a list of values" do
      it "sets argument_type to EnumArgument" do
        expect(opt "-s=a,b,c", :argument_type).to be_a Grammar::EnumArgument
      end
      it "defaults argument_name to the list of values" do
        expect(opt "-s=VAL:a,b,c", :argument_name).to eq "VAL"
        expect(opt "-s=:a,b,c", :argument_name).to eq "a,b,c"
        expect(opt "-s=a,b,c", :argument_name).to eq "a,b,c"
      end
    end
  end
end

