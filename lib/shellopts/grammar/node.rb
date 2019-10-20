module ShellOpts
  module Grammar
    # Root class for Grammar objects
    #
    # Node objects are created by ShellOpts::Grammar.compile that returns a
    # Program object that in turn contains other node objects in a hierarchical
    # structure that reflects the grammar of the program. Only
    # ShellOpts::Grammar.compile should create node objects
    class Node
      # Key (Symbol) of node. Unique within the enclosing command
      attr_reader :key

      def initialize(key)
        @key = key
      end

      # :nocov:
      def dump(&block) 
        puts key.inspect
        indent { yield } if block_given?
      end
      # :nocov:
    end
  end
end
