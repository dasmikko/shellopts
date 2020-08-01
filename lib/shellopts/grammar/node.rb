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

      # Name of node. The name of an option is without the prefixed '-' or
      # '--', the name of a command is without the suffixed '!'. Note that name
      # collisions can happen between options and commands names
      attr_reader :name

      def initialize(key, name)
        @key, @name = key, name
      end

      # :nocov:
      def dump(&block) 
        puts key.inspect
        indent { 
          puts "name: #{name.inspect}"
          yield if block_given?
        }
      end
      # :nocov:
    end
  end
end
