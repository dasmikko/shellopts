module ShellOpts
  module Ast
    class Program < Command
      # Command line arguments. Initially nil but assigned by the parser. This array
      # is the same as the argument array returned by Ast.parse
      attr_accessor :arguments

      def initialize(grammar) 
        super(grammar, grammar.name) 
        @arguments = nil
      end
    end
  end
end
