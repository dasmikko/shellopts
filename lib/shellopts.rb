
require 'indented_io'

require 'constrain'
include Constrain

require 'ext/array.rb'
require 'ext/forward_to.rb'
require 'ext/lcs.rb'
include ForwardTo

require 'shellopts/version.rb'

require 'shellopts/stack.rb'
require 'shellopts/token.rb'
require 'shellopts/grammar.rb'
require 'shellopts/program.rb'
require 'shellopts/args.rb'
require 'shellopts/lexer.rb'
require 'shellopts/argument_type.rb'
require 'shellopts/parser.rb'
require 'shellopts/analyzer.rb'
require 'shellopts/interpreter.rb'
require 'shellopts/ansi.rb'
require 'shellopts/renderer.rb'
require 'shellopts/formatter.rb'
require 'shellopts/dump.rb'


module ShellOpts
  # Base error class
  #
  # Note that errors in the usage of the ShellOpts library are reported using
  # standard exceptions
  #
  class ShellOptsError < StandardError
    attr_reader :token
    def initialize(token)
      super
      @token = token
    end
  end

  # Raised on syntax errors on the command line (eg. unknown option). When
  # ShellOpts handles the exception a message with the following format is
  # printed on standard error:
  #
  #   <program>: <message>
  #   Usage: <program> ...
  #
  class Error < ShellOptsError; end 

  # Default class for program failures. Failures are raised on missing files or
  # illegal paths. When ShellOpts handles the exception a message with the
  # following format is printed on standard error:
  #
  #   <program>: <message>
  #
  class Failure < Error; end

  # ShellOptsErrors during compilation. These errors are caused by syntax errors in the
  # source. Messages are formatted as '<file> <lineno>:<charno> <message>' when
  # handled by ShellOpts
  class CompilerError < ShellOptsError; end
  class LexerError < CompilerError; end 
  class ParserError < CompilerError; end
  class AnalyzerError < CompilerError; end

  # Internal errors. These are caused by bugs in the ShellOpts library
  class InternalError < ShellOptsError; end

  class ShellOpts
    using Ext::Array::ShiftWhile
    using Ext::Array::PopWhile

    # Name of program. Defaults to the name of the executable
    attr_reader :name

    # Specification (String). Initialized by #compile
    attr_reader :spec

    # Array of arguments. Initialized by #interpret
    attr_reader :argv 

    # Grammar. Grammar::Program object. Initialized by #compile
    attr_reader :grammar

    # Resulting ShellOpts::Program object containing options and optional
    # subcommand. Initialized by #interpret
    def program() @program end

    # Array of remaining arguments. Initialized by #interpret
    attr_reader :args

    # Automatically add a -h and a --help option if true
    attr_reader :help

    # Version of client program. If not nil a --version option is added to the program
    def version
      return @version if @version
      exe = caller.find { |line| line =~ /`<top \(required\)>'$/ }&.sub(/:.*/, "")
      file = Dir.glob(File.dirname(exe) + "/../lib/*/version.rb").first
      @version = IO.read(file).sub(/^.*VERSION\s*=\s*"(.*?)".*$/m, '\1') or
          raise ArgumentError, "ShellOpts needs an explicit version"
    end

    # Add message options (TODO)
    attr_accessor :msgopts

    # Floating options
    attr_accessor :float

    # True if ShellOpts lets exceptions through instead of writing an error
    # message and exit
    attr_accessor :exception

    # File of source
    attr_reader :file

    # Debug: Internal variables made public
    attr_reader :tokens
    alias_method :ast, :grammar

    def initialize(name: nil, help: true, version: true, msgopts: false, float: true, exception: false)
      @name = name || File.basename($PROGRAM_NAME)
      @help = help
      @use_version = version ? true : false
      @version = @use_version && @version != true ? @version : nil
      @msgopts, @float, @exception = msgopts, float, exception
    end

    # Compile source and return grammar object. Also sets #spec and #grammar.
    # Returns the grammar
    def compile(spec)
      handle_exceptions {
        @oneline = spec.index("\n").nil?
        @spec = spec.sub(/^\s*\n/, "")
        @file = find_caller_file
        @tokens = Lexer.lex(name, @spec, @oneline)
        ast = Parser.parse(tokens)
        ast.add_version_option if @use_version
        ast.add_help_options if @help
        @grammar = Analyzer.analyze(ast)
      }
      self
    end

    # Use grammar to interpret arguments. Return a ShellOpts::Program and
    # ShellOpts::Args tuple
    #
    def interpret(argv)
      handle_exceptions { 
        @argv = argv.dup
        @program, @args = Interpreter.interpret(grammar, argv, float: float, exception: exception)
        if @program.version?
          puts version 
          exit
        elsif @program.help?
          if @program[:help].name == "-h"
            ShellOpts.brief
          else
            ShellOpts.help
          end
          exit
        end
      }
      self
    end

    # Compile +spec+ and interpret +argv+. Returns a tuple of a
    # ShellOpts::Program and ShellOpts::Args object
    #
    def process(spec, argv)
      compile(spec)
      interpret(argv)
      self
    end

    # Create a ShellOpts object and sets the global instance, then process the
    # spec and arguments. Returns a tuple of a ShellOpts::Program with the
    # options and subcommands and a ShellOpts::Args object with the remaining
    # arguments
    #
    def self.process(spec, argv, **opts)
      ::ShellOpts.instance = shellopts = ShellOpts.new(**opts)
      shellopts.process(spec, argv)
      [shellopts.program, shellopts.args]
    end

    # Write short usage and error message to standard error and terminate
    # program with status 1
    #
    # #error is supposed to be used when the user made an error and the usage
    # is written to help correcting the error
    def error(subject = nil, message)
      $stderr.puts "#{name}: #{message}"
      saved = $stdout
      begin
        $stdout = $stderr
        Formatter.usage(grammar)
        exit 1
      ensure
        $stdout = saved
      end
    end

    # Write error message to standard error and terminate program with status 1
    #
    # #failure doesn't print the program usage because is supposed to be used
    # when the user specified the correct arguments but something else went
    # wrong during processing
    def failure(message)
      $stderr.puts "#{name}: #{message}"
      exit 1
    end

    # Print usage
    def usage() Formatter.usage(@grammar) end

    # Print brief help
    def brief() Formatter.brief(@grammar) end

    # Print help for the given subject or the full documentation if +subject+
    # is nil. Clears the screen beforehand if :clear is true
    def help(subject = nil, clear: true)
      node = (subject ? @grammar[subject] : @grammar) or
          raise ArgumentError, "No such command: '#{subject&.sub(".", " ")}'"
      print '[H[2J' if clear
      Formatter.help(node)
    end

    def self.usage() ::ShellOpts.instance.usage end
    def self.brief() ::ShellOpts.instance.brief end
    def self.help(subject = nil) ::ShellOpts.instance.help(subject) end

  private
    def handle_exceptions(&block)
      return yield if exception
      begin
        yield
      rescue Error => ex
        error(ex.message)
      rescue Failure => ex
        failure(ex.message)
      rescue CompilerError => ex
        filename = file =~ /\// ? file : "./#{file}"
        lineno, charno = find_spec_in_file
        charno = 1 if !@oneline
        $stderr.puts "#{filename}:#{ex.token.pos(lineno, charno)} #{ex.message}"
        exit(1)
      end
    end

    def find_caller_file
      caller.reverse.select { |line| line !~ /^\s*#{__FILE__}:/ }.last.sub(/:.*/, "").sub(/^\.\//, "")
    end

    def self.compare_lines(text, spec)
      return true if text == spec
      return true if text =~ /[#\$\\]/
      false
    end

  public
    # Find line and char index of spec in text. Returns [nil, nil] if not found
    def self.find_spec_in_text(text, spec, oneline)
      text_lines = text.split("\n")
      spec_lines = spec.split("\n")
      spec_lines.pop_while { |line| line =~ /^\s*$/ }

      if oneline
        line_i = nil
        char_i = nil
        char_z = 0

        (0 ... text_lines.size).each { |text_i|
          curr_char_i, curr_char_z = 
              LCS.find_longest_common_substring_index(text_lines[text_i], spec_lines.first.strip)
          if curr_char_z > char_z
            line_i = text_i
            char_i = curr_char_i
            char_z = curr_char_z
          end
        }
        line_i ? [line_i, char_i] : [nil, nil]
      else
        spec_string = spec_lines.first.strip
        line_i = (0 ... text_lines.size - spec_lines.size + 1).find { |text_i|
          (0 ... spec_lines.size).all? { |spec_i|
            compare_lines(text_lines[text_i + spec_i], spec_lines[spec_i])
          }
        } or return [nil, nil]
        char_i, char_z = 
            LCS.find_longest_common_substring_index(text_lines[line_i], spec_lines.first.strip)
        [line_i, char_i || 0]
      end
    end

    def find_spec_in_file
      self.class.find_spec_in_text(IO.read(@file), @spec, @oneline).map { |i| (i || 0) + 1 }
    end

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
        when Ast::Command; Command.grammar(obj) # FIXME
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
  def self.shellopts() instance end

  def self.error(subject = nil, message)
    instance.error(subject, message) if instance? # Never returns
    $stderr.puts "#{File.basename($PROGRAM_NAME)}: #{message}"
    exit 1
  end

  def self.failure(message)
    instance.failure(message) if instance?
    $stderr.puts "#{File.basename($PROGRAM_NAME)}: #{message}"
    exit 1
  end

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

