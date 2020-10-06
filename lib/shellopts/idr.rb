
module ShellOpts
  # Idr models the Internal Data Representation of a program. It is the native
  # representation of a command
  #
  # The IDR should ideally be completely detached from the compile-time grammar
  # and AST but they are only hidden from view in this implementation. Create
  # a Shellopts object instead to access the compiler data
  #
  module Idr
    # Base class for the Idr class hierarchy. It is constructed from an Ast
    # object by #generate. Node is modelled as an element of a hash with a key
    # and a value. Options have their (optional) argument as value while
    # commands use +self+ as value
    class Node
      # Parent node. nil for the top-level Program object
      attr_reader :parent

      # Unique key (within context) for the option or command. nil for the
      # top-level Program object
      attr_reader :key

      # Name of command or option as used on the command line
      attr_reader :name

      # Value of node. This can be a simple value (String, Integer, or Float),
      # an Array of values, or a Idr::Command object. Note that the value of a
      # Command object is the object itself
      #
      # Repeated options are implemented as an Array with one element for each
      # use of the option. The element is nil if the option doesn't take
      # arguments or if an optional argument is missing. 
      attr_reader :value

      # The top-level Program object
      def program() @program ||= (parent&.program || self) end

    protected
      # Copy arguments into instance variables
      def initialize(parent, ast, key, name, value)
        @parent, @ast, @key, @name, @value = parent, ast, key, name, value
      end

      # The AST node for this Idr object
      attr_reader :ast

      # Shorthand to the grammar node for this Idr object
      def grammar() @ast.grammar end
    end

    # Base class for Options
    class Option < Node
    end

    class SimpleOption < Option
    protected
      # Initialize with defauls from the Ast. +value+ is set to true if option
      # doesn't take an argument
      def initialize(parent, ast)
        value = ast.grammar.argument? ? ast.value : true
        super(parent, ast, ast.key, ast.name, value)
      end
    end

    # An OptionGroup models repeated options collapsed into a single key. The
    # name of the group should be set to the name of the key (eg. '--all' if
    # the key is :all)
    class OptionGroup < Option
      # Array of names of the options
      attr_reader :names

      # Array of values of the options
      alias :values :value

      # Name is set to the key name and value to an array of option values
      def initialize(parent, key, name, options)
        @names = options.map(&:name)
        super(parent, nil, key, name, options.map(&:value))
      end
    end

    class Command < Node
      # Hash from key to options with repeated option_list collapsed into a
      # option group. It also include an entry for the subcommand.  Options are
      # ordered by first use on the command line. The command entry will always
      # be last
      attr_reader :options

      # List of command line options in the same order as on the command line
      attr_reader :option_list

      # Subcommand object. Possibly nil
      attr_reader :subcommand

      # True if ident is declared
      def declared?(ident) option?(ident) || subcommand?(ident) end

      # True if ident is declared as an option
      def option?(ident) grammar.options.key?(ident) end

      # True if ident is declared as a command
      def subcommand?(ident) grammar.subcommands.key?(ident) end
      
      # True if ident is present
      def key?(ident)
        declared?(ident) or raise InternalError, "Undefined identifier: #{ident.inspect}"
        key = grammar.identifier2key(ident)
        @options.key?(key)
      end

      # Value of ident. Repeated options are collapsed into an OptionGroup object
      def [](ident)
        declared?(ident) or raise InternalError, "Undefined identifier: #{ident.inspect}"
        key = grammar.identifier2key(ident)
        if @options.key?(key)
          @options[key].value
        elsif option?(key)
          false
        else
          nil
        end
      end

      # Apply defaults recursively. Values can be lambdas that will be evaluated to
      # get the default value. TODO
      def apply(defaults = {}) raise InternalError, "Not implemented" end

      # Return options and command as an array
      def to_a() @ast.values end

      # Return options and command as a hash. The hash also define the
      # singleton method #subcommand that returns the key of the subcommand
      #
      # +key_type+ controls the type of keys used: +:key+ (the default) use the
      # symbolic key, +:name+ use #name. Note that using +:name+ can cause
      # name collisions between option and command names
      #
      # +aliases+ maps from key to replacement key (which could be any object).
      # +aliases+ can be used to avoid name collisions between options and
      # commands when using key_format: :name
      #
      # IDEA: Add a singleton methods to the hash with #name, #usage, etc.
      #
      def to_h(key_type: ::ShellOpts.default_key_type, aliases: {})
        keys = map_keys(key_type, aliases)
        value = {}
        value.define_singleton_method(:subcommand) { nil }
        options.values.each { |opt| # includes subcommand
          key = keys[opt.key]
          case opt
            when Option
              value[key] = opt.value
            when Command
              value[key] = opt.value.to_h(key_type: key_type, aliases: aliases[opt.key] || {})
              value.define_singleton_method(:subcommand) { key } # Redefine
          else
            # :nocov:
            raise InternalError, "Oops"
            # :nocov:
          end
        }
        value
      end

      # Return options and command as a struct
      def to_struct(key_type: ::ShellOpts.default_key_type, aliases: {})
        OptionStruct.new(self, key_type, aliases) 
      end

    protected
      # Initialize an Idr::Command object and all dependent objects
      def initialize(parent, ast)
        super(parent, ast, ast.key, ast.name, self)
        @option_list = ast.options.map { |node| SimpleOption.new(self, node) }
        @subcommand = Command.new(self, ast.subcommand) if ast.subcommand
        @options = @option_list.group_by { |option| option.key }.map { |key, option_list|
          option = 
              if ast.grammar.options[key].repeated?
                OptionGroup.new(self, key, ast.grammar.options[key].key_name, option_list)
              else
                option_list.first
              end
          [key, option]
        }.to_h
        @options[subcommand.key] = @subcommand if @subcommand
      end

      # Internal-key to used-key map. Checks for reserved words and
      # name-collisions
      def map_keys(key_type, aliases, reserved_words = [])
        keys = {}
        used_keys = {}
        (grammar.option_list + grammar.subcommand_list).each { |node|
          internal_key = node.key
          key = aliases[internal_key] || (key_type == :name ? node.name.to_sym : internal_key)
          !reserved_words.include?(key) or
              raise ::ShellOpts::ConversionError, "'#{key}' is a reserved word"
          !used_keys.key?(key) or 
              raise ::ShellOpts::ConversionError, "Name collision between '--#{key}' and '#{key}!'"
          keys[internal_key] = key
          used_keys[key] = true
        }
        keys
      end
    end

    class Program < Command
      # Name of program
      def name() @shellopts.name end
      def name=(name) @shellopts.name = name end

      # Usage string
      def usage() @shellopts.usage end
      def usage=(usage) @shellopts.usage = usage end

      # #key is nil for the top-level Program object
      def key() nil end

      # Remaining command line arguments
      def args() @shellopts.args end

      # Initialize the top-level Idr::Program object
      def initialize(shellopts)
        @shellopts = shellopts
        super(nil, shellopts.ast)
      end

      # Emit error message and a usage description before exiting with status 1
      def error(*args) @shellopts.error(*error_messages) end

      # Emit error message before exiting with status 1
      def fail(*args) @shellopts.fail(*error_messages) end
    end
  end
end

