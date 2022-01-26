
module ShellOpts
  module Grammar
    class Node
      def remove_brief_nodes
        children.delete_if { |node| node.is_a?(Brief) }
      end
    end

    class Command < Node
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
  end

  class Analyzer
    include Grammar

    attr_reader :grammar

    def initialize(grammar)
      @grammar = grammar
    end

    def analyze()
      @grammar.traverse(Command) { |command| command.collect_options }
      @grammar.traverse { |node| node.remove_brief_nodes }
    end

    def Analyzer.analyze(source) self.new(source).analyze end
  end
end

