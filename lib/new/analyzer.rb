
module ShellOpts
  module Grammar
    class Node
      # Links up Command, Option, Usage, and Argument objects
      def link_objekts(command, option)
        children.each { |node| node.link_objekts(command, option) }
      end

      def remove_brief_nodes
        children.delete_if { |node| node.is_a?(Brief) }
#       children.each(&:remove_brief_nodes)
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

      def collect_options
        options.each { |option|
          option.names { |name|
            !@options_hash.key?(name) or raise AnalyzerError, "Duplicate option name: #{option}"
            @options_hash[name] = option
            @options_hash[name.to_sym] = option
          }
        }
      end

      def collect_commands
        commands.each { |command|
          !@commands_hash.key?(ident) or raise AnalyzerError, "Duplicate command name: #{command}"
          @commands_hash[command.ident] = command
          @commands_hash[command.ident.to_s] = command
        }
      end
    end

    class Arguments < Node
      def link_objekts(command, option)
        command.arguments << self
      end
    end

    class Brief < DocNode
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
      @grammar.traverse(Command) { |command| command.collect_options }
      @grammar.traverse { |node| node.remove_brief_nodes }
    end

    def Analyzer.analyze(source) self.new(source).analyze end
  end
end

