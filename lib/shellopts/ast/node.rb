module ShellOpts
  module Ast
    class Node
      # The associated Grammar::Node object
      attr_reader :grammar

      # Key of node. Shorthand for grammar.key
      def key() @grammar.key end

      # Name of node (either program, command, or option name)
      attr_reader :name

      # Initialize an +Ast::Node+ object. +grammar+ is the corresponding
      # grammar object (+Grammar::Node+) and +name+ is the name of the option
      # or sub-command
      def initialize(grammar, name)
        @grammar, @name = grammar, name
      end

      # Return a name/value pair
      def to_tuple
        [name, values]
      end

      # Return either a value (option value), an array of values (command), or
      # nil (option without a value). It must be defined in sub-classes of Ast::Node
      def values() raise end

      # :nocov:
      def dump(&block)
        puts key.inspect
        indent { yield } if block_given?
      end
      # :nocov:
    end
  end
end
