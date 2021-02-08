module ShellOpts
  module Ast
    class Option
      attr_reader :grammar
      attr_reader :name # The actual name used on the command line
      attr_reader :argument

      def initialize(grammar, name, argument)
        @grammar = grammar
        @name = name
        @argument = argument
      end
    end
  end
end
