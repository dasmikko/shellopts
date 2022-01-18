
require 'constrain'

include Constrain

module ShellOpts
  class Parser
    include Grammar
    using Stack

    # Array of token
    attr_reader :tokens

    # AST root node
    attr_reader :program

    def initialize(tokens)
      @tokens = tokens.dup
      @nodes = [] # Stack of Nodes. Follows the indentation of the source
    end

    def parse()
#     @program = Program.new(tokens.shift).parse
      @program = Program.parse(tokens.shift)
      nodes.push @program

      while token = tokens.shift
        while token.char <= indent
          nodes.pop
          !nodes.empty? or err(token, "Illegal indent")
        end

        # Detect option groups
        if token.kind == :option
          if !nodes.top.is_a?(OptionGroup)
            nodes.push OptionGroup.new(nodes.top, token)
          end
          Option.parse(nodes.top, token)
        
        elsif token.kind == :line
          # Detect nested comment groups (code)
          if nodes.top.is_a?(Paragraph)
            code = Code.parse(nodes.top.parent, token) # Using parent of paragraph
            tokens.unshift token
            while tokens.first.kind == :line && tokens.first.char >= code.token.char
              Line.parse(code, tokens.shift)
            end

          # Detect comment groups (paragraphs)
          else
            paragraph = Paragraph.parse(nodes.top, token)
            tokens.unshift token
            while tokens.first.kind == :line && tokens.first.char == paragraph.token.char
              Line.parse(paragraph, tokens.shift)
            end
            nodes.push paragraph # Leave paragraph on stack so we can detect code blocks
          end

        elsif token.kind != :blank
          nodes.push eval("#{token.kind.capitalize}").parse(nodes.top, token)
        end
      end

      @program
    end

    def self.parse(tokens)
      self.new(tokens).parse
    end

  protected
    attr_reader :nodes
    def indent() @nodes.top.token.char end
    def err(token, message) raise ParserError, "#{token.pos} #{message}" end
  end
end


__END__
      def select(*klasses)
        klasses = Array(klasses).flatten
        @children.select { |node| klasses.any? { |klass| node.is_a?(klass) } }
      end

      def reject(*klasses)
        klasses = Array(klasses).flatten
        @children.reject { |node| klasses.any? { |klass| node.is_a?(klass) } }
      end
    class Objekt < Node
      # Command name or canonical option name
      attr_reader :name

      def brief() select(Brief) end
      def content() reject(Brief, Arguments) end


