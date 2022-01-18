
module ShellOpts
  module Idr
    # The parent/child relationship between Idr objects mirrors the Ast node
    # relationships but with some nodes collapsed. It models the documentation
    # structure of the specification. Functional relationships are named
    # explicitly like Command#options or Option#command
    #
    class Node
      attr_reader :parent
      attr_reader :children

      attr_reader :ast

      def initialize(ast, parent)
        @parent = parent
        @parent.children << self if @parent
        @children = []
        @ast = ast
      end
    end

    class Objekt < Node
      attr_reader :command
      attr_reader :name
      attr_reader :brief
      attr_reader :description
      def initialize(ast, parent, command, name)
        super(ast, parent)
        @command = command
        @name = name
      end
    end

    class Option < Objekt
      
    end

    class OptionGroup < Node
    end

    class Command < Objekt
      attr_reader :options
      attr_reader :commands
    end

    class Program < Command
      
    end

    class Paragraph < Node # Has no children
      
    end

    class Code < Node # Code example comment
    end

    class Line < Node
      alias_method :paragraphs, :children
    end

    class Brief < Line 
      # #paragraphs have only one element
    end
  end

  class Analyzer
    attr_reader :ast
    attr_reader :idr

    def initialize(ast)
      @ast = ast
      @idr = Program.new(ast)
    end



    def analyze() @idr end

    def Analyzer.analyze(source) self.new(source).analyze end
  end
end
