
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
    attr_reader :name # Name of program. Defaults to the name of the executable
    attr_reader :spec # Specification. String
    attr_reader :argv # Array of arguments

    def quiet!(quiet = true) @quiet = quiet end
    def quiet?() @quiet end

    def verbose!(verbose = true) @verbose = verbose.is_a?(Integer) ? verbose : (verbose ? 1 : 0) end
    def verbose?() @verbose > 0 end

    def debug!(debug = true) @debug = debug end
    def debug?() @debug end

    # TODO Move to Compiler
    attr_reader :tokens
    def grammar() @idr end
    def program() @expr end
    attr_reader :args

    def initialize(spec, argv, name: nil, exception: false)
      @name = name || File.basename($PROGRAM_NAME)
      @spec, @argv = spec, argv.dup
      @quiet, @verbose, @debug = false, 0, false

      @tokens = Lexer.lex(@name, @spec)
#     @tokens.each(&:dump)
#     puts
#     exit

      @ast = Parser.parse(@tokens)
#     @grammar.dump_ast
#     puts
#     exit


      @idr = Analyzer.analyze(@ast) # @idr and @ast refer to the same object
      @idr.dump_idr(true)
      puts
#     exit

      @expr, @args = Compiler.compile(@idr, @argv)
      Expr::Command.dump(@expr, @args)
      puts 
#     exit
    end

    def self.process(spec, argv, float: true, stdopts: true, msgopts: false, exception: false)
    end

    def self.parse(spec, argv, **opts)
      shellopts = ShellOpts.new(spec, argv, **opts)
      [shellopts.program, shellopts.args]
    end

    def result() [program, arguments] end

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

    def notice(message)
      $stderr.puts "#{name}: #{message}" if !quiet?
    end

    def mesg(message)
      $stdout.puts message if !quiet?
    end

    def verb(level = 1, message)
      $stdout.puts message if level <= @verbose
    end

    def dbg(message)
      $stdout.puts message if debug?
    end

    def usage(subject = nil, device: $stdout, levels: 1, margin: "")
      subject = find_subject(subject)
      device.puts Formatter.usage_string(subject, levels: levels, margin: margin)
    end

    def help(subject = nil, device: $stdout, levels: 10, margin: "", tab: "  ")
      subject = find_subject(subject)
      device.puts Formatter.help_string(subject, levels: levels, margin: margin, tab: tab)
    end

    # Accessor methods to the given command object. The methods are class
    # methods because they can be overridden by options or sub-commands in
    # Expr::Command and they're defined in ShellOpts class to for cosmetic
    # reasons (you don't have to type eg. `Expr::Command.options(command)` but
    # "just" `ShellOpts.options(command)`
    # TODO Better explanation
    forward_self_to ::ShellOpts::Expr::Command, :ident, :name, :grammar, :options, :command, :command!

#   def self.ident(command) ::ShellOpts::Expr::Command.ident(command) end
#   def self.name(command) ::ShellOpts::Expr::Command.name(command) end
#   def self.grammar(command) ::ShellOpts::Expr::Command.grammar(command) end
#   def self.options(command) ::ShellOpts::Expr::Command.options(command) end
#   def self.command(command) ::ShellOpts::Expr::Command.command(command) end
#   def self.command!(command) ::ShellOpts::Expr::Command.command!(command) end

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

  @instance = nil
  def self.instance?() !@instance.nil? end
  def self.instance() @instance or raise Error, "ShellOpts is not initialized" end
  def self.instance=(instance) @instance = instance end

  # Sets the global ShellOpts object
  def self.make(spec, argv, name: nil, exception: false)
    self.instance = ShellOpts.new(spec, argv, name: name, exception: exception)
    [instance.program, instance.arguments]
  end

  forward_self_to :instance, 
      :quiet?, :quiet!,
      :verbose?, :verbose!,
      :debug?, :debug!,
      :error, :failure, :notice,
      :mesg, :verb, :debug,
      :usage, :help

  # The Include module brings the reporting methods into the namespace when
  # included
  module Messages
    forward_to :"ShellOpts.instance",
      :quiet?, :quiet!,
      :verbose?, :verbose!,
      :debug?, :debug!,
      :error, :failure, :notice,
      :mesg, :verb, :debug,
      :usage, :help
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

