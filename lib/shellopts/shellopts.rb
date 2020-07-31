
require "shellopts"

require "shellopts/args.rb"

# TODO
#
# PROCESSING
#   1. Compile usage string and yield a grammar
#   2. Parse the options using the grammar and yield an AST
#   3. Construct the Program model from the AST
#   4. Apply defaults to the model
#   6. Run validations on the model
#   5. Create representation from the model
#

module ShellOpts
  # The command line processing object
  class ShellOpts
    # One of :key, :name, :option
    #
    #         Option   Command
    # :key    key      #command! (no collision)
    # :name   name     #command (possible collision)
    # :option --option #command (multihash, no collision) (TODO)
    #
    DEFAULT_USE = :key

    # Name of program
    attr_reader :name

    # The grammar compiled from the usage string
    attr_reader :grammar

    # The AST parsed from the command line arguments
    attr_reader :ast

    # The IDR generated from the Ast
    attr_reader :idr

    # Object for error & fail messages. Default is to write a message on
    # standard error and exit with status 1
    attr_accessor :messenger

    # Compile a usage string into a grammar and use that to parse command line
    # arguments
    #
    # +usage+ is the usage string, and +argv+ the command line (typically the
    # global ARGV array). +name+ is the name of the program and defaults to the
    # basename of the program
    #
    # Syntax errors in the usage string are caused by the developer and raise a
    # +ShellOpts::CompilerError+ exception.  Errors in the +argv+ arguments are
    # caused by the user and terminates the program with an error message and a
    # short description of its usage
    def initialize(usage, argv, name: PROGRAM, messenger: nil)
      @name = name
      begin
        @grammar = Grammar.compile(name, usage)
        @messenger = messenger || Messenger.new(name, @grammar.usage)
        @ast = Ast.parse(@grammar, argv)
        @idr = Idr.generate(@ast, @messenger)
      rescue Grammar::Compiler::Error => ex
        raise CompilerError.new(5, ex.message)
      rescue Ast::Parser::Error => ex
        raise UserError.new(ex.message)
      end
    end

    # Return an array representation of options and commands in the same order
    # as on the command line. Each option or command is represented by a [name,
    # value] pair. The value of an option is be nil if the option didn't have
    # an argument and else either a String, Integer, or Float. The value of a
    # command is an array of its options and commands
    def to_a() idr.to_a end

    # Return a hash representation of the options. See {ShellOpts::OptionsHash}
    def to_h(use: :key, aliases: {}) @idr.to_h(use: use, aliases: aliases) end

    # Return a struct representation of the options. See {ShellOpts::OptionStruct}
    def to_struct(use: :key, aliases: {}) @idr.to_struct(use: use, aliases: aliases) end

    # List of remaining non-option command line arguments. Returns a Argv object
    def args() Args.new(self, ast&.arguments) end

    # Iterate options and commands as name/value pairs. Same as +to_a.each+
    def each(&block) to_a.each(&block) end

    # Print error messages and usage string and exit with status 1. This method
    # should be called in response to user-errors (eg. specifying an illegal
    # option)
    def error(*msgs, exit: true) @messenger.error(msgs, exit: exit) end

    # Print error message and exit with status 1. This method should called in
    # response to system errors (like disk full)
    def fail(*msgs, exit: true) @messenger.fail(*msgs, exit: exit) end
  end
end


