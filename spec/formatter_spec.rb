
include ShellOpts

describe "Formatter" do
  def method_str(method, source, subject = nil)
    shellopts = ShellOpts::ShellOpts.new(stdopts: false).compile(source)
    grammar = shellopts.compile(source)
    subject = subject ? shellopts.grammar[subject] : shellopts.grammar
    capture { ShellOpts::Formatter.send method, subject }
  end

  def capture(&block)
    save = $stdout
    begin
      $stdout = StringIO.new
      yield
      $stdout.string
    ensure
      $stdout = save
    end
  end

  describe "::usage" do
    def str(source, subject = nil)
      method_str(:usage, source, subject)
    end

    it "puts usage description" do
      s = %(
        -a 
        cmd!
          subcmd!
            A description
      )
      r = undent %(
        Usage: rspec -a [cmd]
      )
      expect(str(s)).to eq r

      s = %(
        -a 
        cmd!
          -b
          subcmd!
            A description
      )
      r = undent %(
        Usage: rspec cmd -b [subcmd]
      )
      expect(str(s, :cmd!)).to eq r
    end

    it "puts a line for each argument description" do
      s = %(
        -- ARG1
        -- ARG2
      )
      r = undent %(
        Usage: rspec ARG1
               rspec ARG2
      )
      expect(str(s)).to eq r

      s = %(
        cmd!
          -- ARG1
          -- ARG2
      )
      r = undent %(
        Usage: rspec cmd ARG1
               rspec cmd ARG2
      )
      expect(str(s, :cmd!)) .to eq r
    end
  end

  describe "::brief" do
    def str(source, subject = nil)
      method_str(:brief, source, subject)
    end

    it "prints a brief description" do
      s = %(
        -a Brief A
          Option description

        -b Brief B
          Option description

        cmd1! Command 1
          Command description

          -c      Brief C
          -d      Brief D

          cmd11!  Command 11
          cmd12!  Command 12

        cmd2! Command 2
      )
      r = undent %(
        Usage 
          rspec -a -b [cmd1|cmd2]

        Options 
          -a                        Brief A
          -b                        Brief B

        Commands 
          cmd1 -c -d [cmd11|cmd12]  Command 1
          cmd2                      Command 2
      )
      expect(str(s)).to eq r

      r = undent %(
        Command 1

        Usage 
          rspec cmd1 -c -d [cmd11|cmd12]

        Options 
          -c      Brief C
          -d      Brief D

        Commands
          cmd11   Command 11
          cmd12   Command 12
      )
      expect(str(s, :cmd1!)).to eq r
    end
  end

  describe "::help" do
    def str(source, subject = nil)
      method_str(:help, source, subject)
    end

    source = %(
      cmd!
        A command

        cmd.nested!
          A nested command

      cmd.subcmd!
        A subcommand
    )

    context "when given a program" do
      it "keeps the indentation levels of subcommands" do
        r = undent %(
          NAME
              rspec

          USAGE
              rspec [cmd]

          COMMANDS
              cmd [nested|subcmd]
                  A command

                  nested
                      A nested command

              cmd subcmd
                  A subcommand

        )
        expect(str(source)).to eq r
      end
    end
    context "when given a subcommand" do
      it "keeps subcommands on the same level" do
        r = undent %(
          NAME
              rspec cmd - A command

          USAGE
              rspec cmd [nested|subcmd]

          DESCRIPTION
              A command

          COMMANDS
              nested
                  A nested command

              subcmd
                  A subcommand
        )
        expect(str(source, "cmd")).to eq r
      end
    end

    context "when given a long definition" do
      def str(width)
        src = "-a,a_long_a_option -b,a_long_b_option a_long_command_name! another_long_command_name!"
        stub_const("ShellOpts::Formatter::USAGE_MAX_WIDTH", width)
        method_str(:help, src).sub(/.*USAGE\s*\n\s*(.*?)\s*\n\s*OPTIONS.*/m, '\1')
      end

      it "tries to keep on one line by compacting" do
        expect(str(80)).to eq "rspec -a -b [a_long_command_name|another_long_command_name]"
      end

      it "uses muliple lines otherwise" do
        r = "rspec --a_long_a_option\n          --a_long_b_option\n          [COMMANDS]"
        expect(str(40)).to eq r
      end
    end
  end
end





__END__

  describe "Formatting" do
    it "parses sub-command with options and arguments" do
      s = %(
        cmd!
          subcmd!
            A description
      )
      s = %(
        cmd! @ Brief description of command
          subcmd! -i,inc -- SUB ARGS @ Brief description of sub-command
            A description
      )
      grammar = compile(s)

#     grammar.dump_idr
#     exit
#     puts "-----------------------------------------------------"     
#     Formatter.brief(grammar)
#     puts "-----------------------------------------------------"     
#     Formatter.help(grammar)
#     puts "-----------------------------------------------------"

#     r = %(
#       Usage:
#         cmd [subcmd] 
#
#       Commands:
#         subcmd --inc SUB ARGS  A description



      puts
      command = grammar[:cmd!]
      Formatter.brief(command)
    end
  end
end





__END__
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
