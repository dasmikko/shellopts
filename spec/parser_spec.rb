require 'spec_helper.rb'
require 'shellopts.rb'

module ShellOpts::Ast
  describe Parser do
    # Parse argv and return a [ast, args] tuple
    def parse(usg = usage, argv)
      grammar = ShellOpts::Grammar.compile("program", usg)
      ShellOpts::Ast.parse(grammar, argv)
    end

    # Parse argv and return a [opt, val] tuple for each option
    def parse_opts(argv)
      parse(argv).options.map { |opt| [opt.name, opt.values] } 
    end

    # Parse argv and return the remaining non-option arguments
    def parse_args(argv) parse(argv).arguments end

    # Take a single argument string (optionally including a space and then a
    # value) and parse it according to the usage string. Return the first (and
    # only) option matched
    def parse_opt(arg) parse_opts(arg.split(" ")).first end

    # Like parse_opt but return the value of the option
    def parse_val(arg) parse_opts(arg.split(" ")).first.last end

    # Like parse_opt but return the first remaining argument
    def parse_arg(arg) parse_args(arg.split(" ")).first end

    describe "#parse" do
      context "Interface" do
        it "type-checks it's arguments" do
          usage = "a"
          argv = "-a"
          grammar = ShellOpts::Grammar.compile("program", usage)
          expect { ShellOpts::Ast.parse(nil, argv) }.to raise_error ShellOpts::InternalError
          expect { ShellOpts::Ast.parse(grammar, nil) }.to raise_error ShellOpts::InternalError
        end

        it "doesn't change the input argv" do
          argv_orig = %w(-a -- arg)
          argv_used = argv_orig.dup
          parse("a", argv_used).arguments
          expect(argv_used).to eq argv_orig
        end

        it "returns a Program object" do
          res = parse("a", %w(-a -- arg))
          expect(res).to be_a Program
        end

        context "the returned Program object" do
          it "has the #arguments member set to the remaining arguments" do
            res = parse("a", %w(-a -- arg))
            expect(res.arguments).to eq %w(arg)
          end
        end

        context "the remaining arguments" do
          let(:usage) { "a b=?" }

          it "contains the non-option arguments" do
            argv = %w(-a -- arg1 arg2)
            expect(parse_args(argv)).to eq %w(arg1 arg2)
          end

          it "doesn't include the first '--'" do
            argv = %w(-a -b -- arg1 arg2 -- arg3)
            expect(parse_args(argv)).to eq %w(arg1 arg2 -- arg3)
          end
        end
      end

      context "Parsing" do
        context "when processing options" do
          let(:usage) { "a,aa +b,bb c,cc= d,dd=?" }

          it "accepts declared options" do
            expect(parse_opt("-a")).to eq ['-a', nil]
            expect { parse_opt("-x") }.to raise_error Parser::Error
            expect(parse_opt("--aa")).to eq ['--aa', nil]
            expect { parse_opt("--xx") }.to raise_error Parser::Error
          end

          it "accepts repeated options" do
            expect(parse_opts %w(-b -b --bb --bb)).to eq [['-b', nil], ['-b', nil], ['--bb', nil], ['--bb', nil]]
            expect { parse_opts %w(-a -a) }.to raise_error Parser::Error
          end

          it "accepts mandatory arguments" do
            expect { parse_opt("-c") }.to raise_error Parser::Error
            expect(parse_opt("-cx")).to eq ['-c', 'x']
            expect(parse_opt("-c x")).to eq ['-c', 'x']
            expect { parse_opt("--cc") }.to raise_error Parser::Error
            expect(parse_opt("--cc=")).to eq ['--cc', '']
            expect(parse_opt("--cc=xx")).to eq ['--cc', 'xx']
            expect(parse_opt("--cc xx")).to eq ['--cc', 'xx']
          end

          it "accepts optional arguments" do
            expect(parse_opt("-d")).to eq ['-d', nil]
            expect(parse_opt("-dx")).to eq ['-d', 'x']
            expect(parse_opt("-d x")).to eq ['-d', nil]
            expect(parse_opt("--dd")).to eq ['--dd', nil]
            expect(parse_opt("--dd=")).to eq ['--dd', '']
            expect(parse_opt("--dd=xx")).to eq ['--dd', 'xx']
            expect(parse_opt("--dd xx")).to eq ['--dd', nil]
          end

          it "rejects unspecified arguments" do
            expect { parse_opt("--aa=val") }.to raise_error Parser::Error
          end

          it "accepts concatenated short options" do
            expect(parse_opts(%w(-abd))).to eq [["-a", nil], ["-b", nil], ["-d", nil]]
            expect(parse_opts(%w(-abcd))).to eq [["-a", nil], ["-b", nil], ["-c", "d"]]
          end
        end
        context "when processing option arguments" do
          let(:usage) { "i=#? f=$?" }

          it "converts integer arguments" do
            expect(parse_val("-i")).to eq nil
            expect(parse_val("-i42")).to eq 42
            expect { parse_val("-ix") }.to raise_error Parser::Error
            expect { parse_val("-i2.0") }.to raise_error Parser::Error
          end

          it "converts float arguments" do
            expect(parse_val("-f")).to eq nil
            expect(parse_val("-f4")).to eq 4.0
            expect(parse_val("-f4.2")).to eq 4.2
            expect { parse_val("-fx") }.to raise_error Parser::Error
            expect { parse_val("-f2.") }.to raise_error Parser::Error
          end

        end
        context "when processing commands" do
          let(:usage) { "cmd1! cmd1.cmd11! cmd2!" }

          it "consider non-nested commands arguments" do
            argv = %w(cmd1 cmd11 cmd2)
            res = parse(argv)
            expect(res.command.to_tuple).to eq [ "cmd1", [ ["cmd11", []] ] ]
            expect(res.arguments).to eq %w(cmd2)

            argv = %w(cmd2 cmd1)
            res = parse(argv)
            expect(res.command.to_tuple).to eq [ "cmd2", [] ]
            expect(res.arguments).to eq %w(cmd1)
          end
        end
      end
    end
  end
end

