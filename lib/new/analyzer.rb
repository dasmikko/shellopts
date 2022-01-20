
module ShellOpts
  module Grammar
    class Node
      def link_objekts(command, option)
        children.each { |node| node.link_objekts(command, option) }
      end

      def remove_brief_nodes
        children.delete_if { |node| node.is_a?(Brief) }
        children.each(&:remove_brief_nodes)
      end
    end

    class Option < Node
      def link_objekts(command, option)
        # TODO Check for name collisions
        command.options << self
        super(command, self)
      end
    end

    class Command < Node
      def link_objekts(command = nil, option = nil)
        # TODO Check for name collisions
        command.commands << self if command
        children.each { |node| node.link_objekts(self, nil) }
      end
    end

    class Arguments < Node
      def link_objekts(command, option)
        command.arguments << self
      end
    end

    class Brief < Line
      def link_objekts(command, option)
        (option || command).brief = self
      end
    end
  end

  class Analyzer
    include Grammar
    using Stack

    attr_reader :grammar

    def initialize(grammar)
      @grammar = grammar
      @objekts = [] # Stack
    end

    def analyze()
      @grammar.link_objekts
      @grammar.remove_brief_nodes
      @grammar.dump_command
    end

    def Analyzer.analyze(source) self.new(source).analyze end
  end
end

