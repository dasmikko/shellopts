require "shellopts/version"

require 'shellopts/compiler.rb'
require 'shellopts/parser.rb'
require 'shellopts/utils.rb'

# ShellOpts is a library for parsing command line options and sub-commands. The
# library API consists of the methods {ShellOpts.process}, {ShellOpts.error},
# and {ShellOpts.fail} and the result class {ShellOpts::ShellOpts}
#
# ShellOpts inject the constant PROGRAM into the global scope. It contains the 
# name of the program
#
module ShellOpts
  # Return the hidden +ShellOpts::ShellOpts+ object (see .process)
  def self.shellopts()
    @shellopts
  end

  # Process command line options and arguments.  #process takes a usage string
  # defining the options and the array of command line arguments to be parsed
  # as arguments
  #
  # If called with a block, the block is called with name and value of each
  # option or command and #process returns a list of remaining command line
  # arguments. If called without a block a ShellOpts::ShellOpts object is
  # returned
  # 
  # The value of an option is its argument, the value of a command is an array
  # of name/value pairs of options and subcommands. Option values are converted
  # to the target type (String, Integer, Float) if specified
  #
  # Example
  #
  #   # Define options
  #   USAGE = 'a,all g,global +v,verbose h,help save! snapshot f,file=FILE h,help'
  #
  #   # Define defaults
  #   all = false
  #   global = false
  #   verbose = 0
  #   save = false
  #   snapshot = false
  #   file = nil
  #
  #   # Process options
  #   argv = ShellOpts.process(USAGE, ARGV) do |name, value|
  #     case name
  #       when '-a', '--all'; all = true
  #       when '-g', '--global'; global = value
  #       when '-v', '--verbose'; verbose += 1
  #       when '-h', '--help'; print_help(); exit(0)
  #       when 'save'
  #         save = true
  #         value.each do |name, value|
  #           case name
  #             when '--snapshot'; snapshot = true
  #             when '-f', '--file'; file = value
  #             when '-h', '--help'; print_save_help(); exit(0)
  #           end
  #         end
  #     else
  #       raise "Not a user error. The developer forgot or misspelled an option"
  #     end
  #   end
  #
  #   # Process remaining arguments
  #   argv.each { |arg| ... }
  #
  # If an error is encountered while compiling the usage string, a
  # +ShellOpts::Compiler+ exception is raised. If the error happens while
  # parsing the command line arguments, the program prints an error message and
  # exits with status 1. Failed assertions raise a +ShellOpts::InternalError+
  # exception
  #
  # Note that you can't process more than one command line at a time because
  # #process saves a hidden {ShellOpts::ShellOpts} class variable used by the
  # class methods #error and #fail. Call #reset to clear the global object if
  # you really need to parse more than one command line. Alternatively you can
  # create +ShellOpts::ShellOpts+ objects yourself and use the object methods
  # #error and #fail instead:
  #
  #   shellopts = ShellOpts::ShellOpts.new(USAGE, ARGS)
  #   shellopts.each { |name, value| ... }
  #   shellopts.args.each { |arg| ... }
  #   shellopts.error("Something went wrong")
  #
  # Use #shellopts to get the hidden +ShellOpts::ShellOpts+ object
  #
  def self.process(usage, argv, program_name: PROGRAM, &block)
    if !block_given?
      ShellOpts.new(usage, argv, program_name: program_name)
    else
      @shellopts.nil? or raise InternalError, "ShellOpts class variable already initialized"
      @shellopts = ShellOpts.new(usage, argv, program_name: program_name)
      @shellopts.each(&block)
      @shellopts.args
    end
  end

  # Reset the hidden +ShellOpts::ShellOpts+ class variable so that you can process
  # another command line
  def self.reset()
    @shellopts = nil
  end

  # Print error message and usage string and exit with status 1. It use the
  # current ShellOpts object if defined. This method should be called in
  # response to user-errors (eg. specifying an illegal option)
  def self.error(*msgs)
    program = @shellopts&.program_name || PROGRAM
    usage = @shellopts&.usage || (defined?(USAGE) && USAGE ? Grammar.compile(PROGRAM, USAGE).usage : nil)
    emit_and_exit(program, usage, *msgs)
  end

  # Print error message and exit with status 1. It use the current ShellOpts
  # object if defined. This method should not be called in response to
  # user-errors but system errors (like disk full)
  def self.fail(*msgs)
    program = @shellopts&.program_name || PROGRAM
    emit_and_exit(program, nil, *msgs)
  end

  # The compilation object
  class ShellOpts
    # Name of program
    attr_reader :program_name

    # Usage string. Shorthand for +grammar.usage+
    def usage() @grammar.usage end

    # The grammar compiled from the usage string. If #ast is defined, it's
    # equal to ast.grammar
    attr_reader :grammar

    # The AST resulting from parsing the command line arguments
    attr_reader :ast

    # List of remaining non-option command line arguments. Shorthand for ast.arguments
    def args() @ast.arguments end

    # Compile a usage string into a grammar and use that to parse command line
    # arguments
    #
    # +usage+ is the usage string, and +argv+ the command line (typically the
    # global ARGV array). +program_name+ is the name of the program and is
    # used in error messages. It defaults to the basename of the program
    #
    # Errors in the usage string raise a CompilerError exception. Errors in the
    # argv arguments terminates the program with an error message
    def initialize(usage, argv, program_name: File.basename($0))
      @program_name = program_name
      begin
        @grammar = Grammar.compile(program_name, usage)
        @ast = Ast.parse(@grammar, argv)
      rescue Grammar::Compiler::Error => ex
        raise CompilerError.new(5, ex.message)
      rescue Ast::Parser::Error => ex
        error(ex.message)
      end
    end

    # Unroll the AST into a nested array
    def to_a
      @ast.values
    end

    # Iterate the result as name/value pairs. See {ShellOpts.process} for a
    # detailed description
    def each(&block)
      if block_given?
        to_a.each { |*args| yield(*args) }
      else
        to_a # FIXME: Iterator
      end
    end

    # Print error message and usage string and exit with status 1. This method
    # should be called in response to user-errors (eg. specifying an illegal
    # option)
    def error(*msgs)
      ::ShellOpts.emit_and_exit(program_name, usage, msgs)
    end

    # Print error message and exit with status 1. This method should not be
    # called in response to user-errors but system errors (like disk full)
    def fail(*msgs)
      ::ShellOpts.emit_and_exit(program_name, nil, msgs)
    end
  end

  # Base class for ShellOpts exceptions
  class Error < RuntimeError; end

  # Raised when an error is detected in the usage string
  class CompilerError < Error
    def initialize(start, message)
      super(message)
      set_backtrace(caller(start))
    end
  end

  # Raised when an internal error is detected
  class InternalError < Error; end

private
  @shellopts = nil

  def self.emit_and_exit(program, usage, *msgs)
    $stderr.puts "#{program}: #{msgs.join}"
    $stderr.puts "Usage: #{program} #{usage}" if usage
    exit 1
  end
end

PROGRAM = File.basename($PROGRAM_NAME)
