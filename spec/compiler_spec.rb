require 'spec_helper.rb'
require 'shellopts.rb'

# Match if Program object have the given option names
RSpec::Matchers.define :have_names do |*names|
  match do |actual|
    option_names = actual.option_list.map(&:names).flatten
    Array(names).flatten.all? { |n| option_names.include?(n) }
  end
end

# Match if Program object's first option have the given flags
RSpec::Matchers.define :have_flags do |*flags|
  match do |actual|
    list = actual.option_list.first.flags
    Array(flags).flatten.all? { |f| list.include?(f) }
  end
end

module ShellOpts::Grammar
  describe Compiler do
    def compile(usage)
      Compiler.new("program", usage).call
    end

    describe "#compile" do 
      it "type-checks its arguments" do
        expect { ShellOpts::Grammar.compile(nil, "") }.to raise_error Compiler::Error
        expect { ShellOpts::Grammar.compile("", nil) }.to raise_error Compiler::Error
      end

      # FIXME: None of the following tests run the #compile method!
      it "returns a Grammar::Program object" do
        grammar = compile("a b c -- arg")
        expect(grammar).to be_a ShellOpts::Grammar::Program
      end

      it "records the remaining arguments" do
        grammar = compile("a b -- arg1 arg2")
        expect(grammar.args).to eq %w(arg1 arg2)
        grammar = compile("a --")
        expect(grammar.args).to eq %w()
      end

      it "accepts empty input" do
        grammar = compile("")
        expect(grammar.option_list + grammar.command_list).to eq []
      end

      it "accepts \"--\" as input" do
        grammar = compile("--")
        expect(grammar.option_list + grammar.command_list).to eq []
      end

      it "stops compiling when '--' is detected" do
        expect(compile("a -- b")).to have_names("-a")
        expect(compile("a -- b")).not_to have_names("-b")
      end

      context "when compiling identifiers" do
        it "accept ASCII letters, digits, underscore, and dash" do
          expect(compile("aA0_-")).to have_names "--aA0_-"
          expect { compile("%") }.to raise_error Compiler::Error
        end

        it "disallows empty names" do
          expect { compile(",a") }.to raise_error Compiler::Error
          expect { compile("a,") }.to raise_error Compiler::Error
          expect { compile(",a,") }.to raise_error Compiler::Error
        end

        it "disallows prefixed '-'" do
          expect { compile("-a") }.to raise_error Compiler::Error
        end
      end

      context "when compiling options" do
        it "parses 'a' as a short option" do
          expect(compile("a")).to have_names "-a"
        end

        it "parses 'ab' as a long option" do
          expect(compile("ab")).to have_names "--ab"
        end

        it "parses 'a,b,c' as a list of options" do
          expect(compile("a,b,c")).to have_names %w(-a -b -c)
        end

        it "disallows duplicate definitions" do
          expect { compile("a a") }.to raise_error Compiler::Error
        end
      end

      context "when compiling option flags" do
        it "accepts '+'" do
          expect(compile("+a")).to have_flags(:repeated)
        end

        it "accepts '='" do
          expect(compile("a=")).to have_flags(:argument)
        end

        it "accepts '#'" do
          expect(compile("a=#")).to have_flags(:argument, :integer)
        end

        it "accepts '$'" do
          expect(compile("a=$")).to have_flags(:argument, :float)
        end

        it "accepts '?'" do
          expect(compile("a=?")).to have_flags(:argument, :optional)
        end

        it "accepts named arguments" do
          expect(compile("a=ARG").option_list.first.label).to eq "ARG"
        end

        it "accepts legal combinations of the above" do
          srcs = []
          for repeated in [nil, "+"]
            for argument in [nil, "="]
              if argument
                for type in [nil, "#", "$"]
                  for label in [nil, "LABEL"]
                    for optional in [nil, "?"]
                      srcs << "#{repeated}opt#{argument}#{type}#{label}#{optional}"
                    end
                  end
                end
              else
                srcs << "#{repeated}opt"
              end
            end
          end
          expect { srcs.each { |src| compile(src) } }.not_to raise_error
        end
      end

      context "when compiling commands" do
        it "recognizes 'cmd!' as a command" do
          program = compile("cmd!")
          command = program.commands["cmd"]
          expect(program.commands.size).to eq 1
          expect(command.commands.size).to eq 0
        end
        it "recognizes 'cmd1.cmd2!' as a sub-command" do
          program = compile("cmd1! cmd1.cmd2!")
          command = program.commands["cmd1"]
          subcommand = command.commands["cmd2"]
          expect(program.commands.size).to eq 1
          expect(command.commands.size).to eq 1
          expect(subcommand.commands.size).to eq 0
        end
        it "allows arbitrary number of sub-commands" do
          program = compile("cmd1! cmd1.cmd1! cmd1.cmd2!")
          command = program.commands["cmd1"]
          subcommand1 = command.commands["cmd1"]
          subcommand2 = command.commands["cmd2"]
          expect(program.commands.size).to eq 1
          expect(command.commands.size).to eq 2
          expect(subcommand1.commands.size).to eq 0
          expect(subcommand2.commands.size).to eq 0
        end
        it "allows arbitrary nesting of commands" do
          program = compile("cmd1! cmd1.cmd2! cmd1.cmd2.cmd3!")
          command1 = program.commands["cmd1"]
          command2 = command1.commands["cmd2"]
          command3 = command2.commands["cmd3"]
          expect(program.commands.size).to eq 1
          expect(command1.commands.size).to eq 1
          expect(command2.commands.size).to eq 1
          expect(command3.commands.size).to eq 0
        end
        it "disallows duplicate commands" do
          expect { compile("cmd cmd.cmd1 cmd") }.to raise_error(Compiler::Error)
          expect { compile("cmd cmd.cmd1 cmd.cmd2") }.to raise_error(Compiler::Error)
        end
        it "disallows non-existing parent commands" do
          expect { compile("cmd.cmd1") }.to raise_error(Compiler::Error)
        end
        it "associates options with the preceding command" do
          program = compile("a cmd1! b cmd1.cmd1! c cmd1.cmd2! d cmd2! e")
          command1 = program.commands["cmd1"]
          subcommand1 = command1.commands["cmd1"]
          subcommand2 = command1.commands["cmd2"]
          command2 = program.commands["cmd2"]
          expect(program.option_list.map(&:names).flatten).to eq %w(-a)
          expect(command1.option_list.map(&:names).flatten).to eq %w(-b)
          expect(subcommand1.option_list.map(&:names).flatten).to eq %w(-c)
          expect(subcommand2.option_list.map(&:names).flatten).to eq %w(-d)
          expect(command2.option_list.map(&:names).flatten).to eq %w(-e)
        end
      end
    end
  end
end
