module ShellOpts
  module Ast
    class Command < Node
      # Array of options (Ast::Option). Initially empty but filled out by the
      # parser
      attr_reader :options

      # Optional sub-command (Ast::Command). Initially nil but assigned by the
      # parser
      attr_accessor :subcommand 

      def initialize(grammar, name)
        super(grammar, name)
        @options = []
        @subcommand = nil
      end

      # Array of option or command tuples
      def values
        (options + (Array(subcommand || []))).map { |node| node.to_tuple }
      end

      # :nocov:
      def dump(&block)
        super {
          yield if block_given?
          puts "options:"
          indent { options.each { |opt| opt.dump } }
          print "subcommand:"
          if subcommand
            puts
            indent { subcommand.dump }
          else
            puts "nil"
          end
        }
      end
      # :nocov:
    end
  end
end
