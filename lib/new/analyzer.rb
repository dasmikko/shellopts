
module ShellOpts
  module Grammar
    class Node
      def remove_brief_nodes
        children.delete_if { |node| node.is_a?(Brief) }
      end

      def analyzer_error(token, message) raise AnalyzerError, "#{token.pos} #{message}" end
    end

    class Command < IdrNode
      def collect_options
        options.each { |option|
          option.idents.zip(option.names).each { |ident, name|
            !@options_hash.key?(name) or 
                analyzer_error option.token, "Duplicate option name: #{name}"
            @options_hash[name] = option
            !@options_hash.key?(ident) or 
                analyzer_error option.token, "Can't use both #{@options_hash[ident].name} and #{name}"
            @options_hash[ident] = option
          }
        }
      end

      def collect_commands
        commands.each { |command|
          # Check for dash-collision
          !@commands_hash.key?(command.name) or 
              analyzer_error command.token, "Duplicate command name: #{command.name}"
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
      @grammar.traverse(Command) { |command| 
        command.collect_options 
        command.collect_commands
      }
      
      @grammar.traverse { |node| node.remove_brief_nodes }
    end

    def Analyzer.analyze(source) self.new(source).analyze end
  end
end

