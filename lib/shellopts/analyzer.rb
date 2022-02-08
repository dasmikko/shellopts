
module ShellOpts
  module Grammar
    class Node
      def remove_brief_nodes
        children.delete_if { |node| node.is_a?(Brief) }
      end

      def remove_arg_descr_nodes
        children.delete_if { |node| node.is_a?(ArgDescr) }
      end

      def analyzer_error(token, message) raise AnalyzerError, "#{token.pos} #{message}" end
    end

    class Command
      def collect_options
        @options = option_groups.map(&:options).flatten
      end

      # Move options before first command
      def reorder_options
        if commands.any?
          if i = children.find_index { |child| child.is_a?(Command) }
            options, rest = children[i+1..-1].partition { |child| child.is_a?(OptionGroup) }
            @children = children[0..i-1] + options + children[i..i] + rest
          end
        end
      end

      def compute_option_hashes
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

      def compute_command_hashes
        commands.each { |command|
          # Check for dash-collision
          !@commands_hash.key?(command.name) or 
              analyzer_error command.token, "Duplicate command name: #{command.name}"
          @commands_hash[command.name] = command
          @commands_hash[command.ident] = command
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
      @grammar.traverse(Grammar::Command) { |command|
        command.reorder_options
        command.collect_options
        command.compute_option_hashes
        command.compute_command_hashes
      }
      @grammar.traverse { |node| 
        node.remove_brief_nodes 
        node.remove_arg_descr_nodes
      }

      @grammar
    end

    def Analyzer.analyze(source) self.new(source).analyze end
  end
end

