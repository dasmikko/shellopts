require "shellopts/version"

require "ext/algorithm.rb"
require "ext/ruby_env.rb"

require "shellopts/constants.rb"
require "shellopts/exceptions.rb"

require "shellopts/grammar/analyzer.rb"
require "shellopts/grammar/lexer.rb"
require "shellopts/grammar/parser.rb"
require "shellopts/grammar/command.rb"
require "shellopts/grammar/option.rb"

require "shellopts/ast/parser.rb"
require "shellopts/ast/command.rb"
require "shellopts/ast/option.rb"

require "shellopts/args.rb"
require "shellopts/formatter.rb"

if RUBY_ENV == "development"
  require "shellopts/grammar/dump.rb"
  require "shellopts/ast/dump.rb"
end

$verb = nil
$quiet = nil
$shellopts = nil

module ShellOpts
  class ShellOpts
    attr_reader :name # Name of program. Defaults to the name of the executable
    attr_reader :spec
    attr_reader :argv

    attr_reader :grammar
    attr_reader :program
    attr_reader :arguments

    def initialize(spec, argv, name: nil, exception: false)
      @name = name || File.basename($PROGRAM_NAME)
      @spec, @argv = spec, argv.dup
      exprs = Grammar::Lexer.lex(@spec)
      commands = Grammar::Parser.parse(@name, exprs)
      @grammar = Grammar::Analyzer.analyze(commands)

      begin
        @program, @arguments = Ast::Parser.parse(@grammar, @argv)
      rescue Error => ex
        raise if exception
        error(ex.subject, ex.message)
      end
    end

    def error(subject = nil, message)
      $stderr.puts "#{name}: #{message}"
      usage(subject, device: $stderr)
      exit 1
    end

    def fail(message)
      $stderr.puts "#{name}: #{message}"
      exit 1
    end

    def usage(subject = nil, device: $stdout, levels: 1, margin: "")
      subject = find_subject(subject)
      device.puts Formatter.usage_string(subject, levels: levels, margin: margin)
    end

    def help(subject = nil, device: $stdout, levels: 10, margin: "", tab: "  ")
      subject = find_subject(subject)
      device.puts Formatter.help_string(subject, levels: levels, margin: margin, tab: tab)
    end

  private
    def lookup(name)
      a = name.split(".")
      cmd = grammar
      while element = a.shift
        cmd = cmd.commands[element]
      end
      cmd
    end

    def find_subject(obj)
      case obj
        when String; lookup(obj)
        when Ast::Command; Command.grammar(obj)
        when Grammar::Command; obj
        when NilClass; grammar
      else
        raise Internal, "Illegal object: #{obj.class}"
      end
    end
  end

  def self.process(spec, argv, name: nil, exception: false)
    $shellopts = ShellOpts.new(spec, argv, name: name, exception: exception)
    [$shellopts.program, $shellopts.arguments]
  end

  def self.error(subject = nil, message)
    $shellopts.error(subject, message)
  end

  def self.fail(message)
    $shellopts.fail(message)
  end

  def self.help(subject = nil, device: $stdout, levels: 10, margin: "", tab: "  ")
    $shellopts.help(subject, device: device, levels: levels, margin: margin, tab: tab)
  end

  def self.usage(subject = nil, device: $stdout, levels: 1, margin: "")
    $shellopts.usage(subject, device: device, levels: levels, margin: margin)
  end
end

