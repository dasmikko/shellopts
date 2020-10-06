
require "shellopts"

require "shellopts/args.rb"

# TODO
#
# PROCESSING
#   1. Compile spec string and yield a grammar
#   2. Parse the options using the grammar and yield an AST
#   3. Construct the Program model from the AST
#   4. Apply defaults to the model
#   6. Run validations on the model
#   5. Create representation from the model
#

module ShellOpts
  # The command line processing object
  class ShellOpts
    # Name of program
    attr_accessor :name

    # Usage string. If #usage is nil, the auto-generated default is used
    def usage() @usage || @grammar.usage end
    def usage=(usage) @usage = usage end

    # Specification of the command
    attr_reader :spec

    # Original argv argument
    attr_reader :argv

    # The grammar compiled from the spec string
    attr_reader :grammar

    # The AST parsed from the command line arguments
    attr_reader :ast

    # The IDR generated from the Ast
    attr_reader :idr

    # Compile a spec string into a grammar
    #
    # +spec+ is the spec string, and +argv+ the command line (typically the
    # global ARGV array). +name+ is the name of the program and defaults to the
    # basename of the program
    #
    # Syntax errors in the spec string are caused by the developer and cause
    # #initialize to raise a +ShellOpts::CompilerError+ exception. Errors in
    # the +argv+ arguments are caused by the user and cause #process to raise
    # ShellOpts::UserError exception
    #
    # TODO: Change to (name, spec, argv, usage: nil) because
    # ShellOpts::ShellOpts isn't a magician like the ShellOpts module
    def initialize(spec, argv, name: ::ShellOpts.default_name, usage: ::ShellOpts.default_usage)
      @name = name
      @spec = spec
      @usage = usage
      @argv = argv
      begin
        @grammar = Grammar.compile(@name, @spec)
      rescue Grammar::Compiler::Error => ex
        raise CompilerError.new(5, ex.message)
      end
    end

    # Process command line arguments and return self. Raises a
    # ShellOpts::UserError in case of an error
    def process
      begin
        @ast = Ast.parse(@grammar, @argv)
        @idr = Idr.generate(self)
      rescue Ast::Parser::Error => ex
        raise UserError.new(ex.message)
      end
      self
    end

    # Return an array representation of options and commands in the same order
    # as on the command line. Each option or command is represented by a [name,
    # value] pair. The value of an option is be nil if the option didn't have
    # an argument and else either a String, Integer, or Float. The value of a
    # command is an array of its options and commands
    def to_a() idr.to_a end

    # Return a hash representation of the options. See {ShellOpts::OptionsHash}
    def to_h(key_type: ::ShellOpts.default_key_type, aliases: {})
      @idr.to_h(key_type: :key_type, aliases: aliases) 
    end

    # TODO
    # Return OptionHash object
    # def to_hash(...)

    # Return a struct representation of the options. See {ShellOpts::OptionStruct}
    def to_struct(key_type: ::ShellOpts.default_key_type, aliases: {}) 
      @idr.to_struct(key_type: key_type, aliases: aliases) 
    end

    # List of remaining non-option command line arguments. Returns a Argv object
    def args() Args.new(self, ast&.arguments) end

    # Iterate options and commands as name/value pairs. Same as +to_a.each+
    def each(&block) to_a.each(&block) end

    # Print error messages and spec string and exit with status 1. This method
    # should be called in response to user-errors (eg. specifying an illegal
    # option)
    def error(*msgs, exit: true)
      msg = "#{name}: #{msgs.join}\n" + (@usage ? usage : "Usage: #{name} #{usage}")
      $stderr.puts msg.rstrip
      exit(1) if exit
    end

    # Print error message and exit with status 1. This method should called in
    # response to system errors (like disk full)
    def fail(*msgs, exit: true)
      $stderr.puts "#{name}: #{msgs.join}"
      exit(1) if exit
    end
  end
end

