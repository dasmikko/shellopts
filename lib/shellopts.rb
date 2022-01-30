
$quiet = nil
$verb = nil
$debug = nil
$shellopts = nil

require 'indented_io'

#$LOAD_PATH.unshift "../constrain/lib"
require 'constrain'
include Constrain

require 'ext/array.rb'
require 'ext/forward_to.rb'
include ForwardTo

require 'shellopts/version.rb'

require 'shellopts/stack.rb'
require 'shellopts/token.rb'
require 'shellopts/grammar.rb'
require 'shellopts/expr.rb'
require 'shellopts/lexer.rb'
require 'shellopts/argument_type.rb'
require 'shellopts/parser.rb'
require 'shellopts/analyzer.rb'
require 'shellopts/compiler.rb'
require 'shellopts/dump.rb'

# There are three interfaces for the reporting methods:
#   o On a shellopts object
#   o On the Shellopts module
#   o In the global scope if ShellOpts::Include is included
#

module ShellOpts
  class Error < StandardError; end
  class CompilerError < Error; end
  class LexerError < Error; end
  class ParserError < CompilerError; end
  class AnalyzerError < CompilerError; end
  class InterpreterError < Error; end # Error by the developer
  class UserError < Error; end
  class Failure < Error; end
  class InternalError < Error; end

  class ShellOpts
    # Name of program. Defaults to the name of the executable
    attr_reader :name

    # Specification. String
    attr_reader :spec

    # Array of arguments
    attr_reader :argv 

    # Resulting ShellOpts::Program object containing options and subcommand if present
    def program() @program end

    # Array of remaining arguments
    attr_reader :args

    def initialize(spec, argv, name: nil)
      @name = name || File.basename($PROGRAM_NAME)
      @spec, @argv = spec, argv.dup
    end

    def process(float: true, stdopts: true, msgopts: false, exception: false)
      tokens = Lexer.lex(name, spec)
      ast = Parser.parse(tokens)
      idr = Analyzer.analyze(ast) # @idr and @ast refer to the same object

      # ... add stdopts options ...
      # ... add msgopts options ...

      @program, @args = Compiler.compile(idr, argv, float: float, exception: exception)

      # Process stdopts options
      # Process msgopts options

      idr.dump_idr(true)
      Expr::Command.dump(@program, @args)
      puts 
      [@program, @args]
    end

    # Create a ShellOpts object and sets the global instance if not defined
    def self.process(spec, argv, name: nil, **opts)
      shellopts = ShellOpts.new(spec, argv, name: name)
      ::ShellOpts.instance = shellopts if !::ShellOpts.instance?
      shellopts.process(**opts)
    end

    def error(subject = nil, message)
      $stderr.puts "#{name}: #{message}"
      usage(subject, device: $stderr)
      exit 1
    end

    def failure(message)
      $stderr.puts "#{name}: #{message}"
      exit 1
    end

#   def exception(message)
#     $stderr.puts "#{name}: Unexpected error"
#     $stderr.puts message
#     exit 1
#   end

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

  def self.process(spec, argv, msgopts: false, **opts)
    msgopts ||= Messages.is_included?
    ShellOpts.process(spec, argv, msgopts: msgopts, **opts)
  end

  @instance = nil
  def self.instance?() !@instance.nil? end
  def self.instance() @instance or raise Error, "ShellOpts is not initialized" end
  def self.instance=(instance) @instance = instance end

  forward_self_to :instance, :error, :failure

  # The Include module brings the reporting methods into the namespace when
  # included
  module Messages
    @is_included = false
    def self.is_included?() @is_included end
    def self.include(...)
      @is_included = true
      super
    end

    def notice(message)
      $stderr.puts "#{name}: #{message}" if !quiet?
    end

    def mesg(message)
      $stdout.puts message if !quiet?
    end

    def verb(level = 1, message)
      $stdout.puts message if level <= @verbose
    end

    def debug(message)
      $stdout.puts message if debug?
    end
  end

  module ErrorHandling
    # TODO: Set up global exception handlers
  end
end








__END__

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

