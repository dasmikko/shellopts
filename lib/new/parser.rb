
require 'constrain'

include Constrain

module ShellOpts
  module Grammar
    class Node
      def parse
        ;
      end

      def self.parse(parent, token)
        this = self.new(parent, token)
        this.parse
        this
      end
    end

    # Grammar
    #   [ "+" ] name-list [ "=" [ label ] [ ":" [ "#" | "$" | enum | special-constant ] ] [ "?" ] ]
    #
    #   -a=           # syntax error
    #   -a=#          # Renders as -a=INT
    #   -b=$          # Renders as -b=NUM
    #   -c=a,b,c      # Renders as -c=a|b|c
    #   -d=3..5       # Renders as -d=3..5
    #   -e=:DIR       # Renders as -e=DIR
    #   -f=:FILE      # Renders as -f=FILE
    #
    #   -o=COUNT
    #   -a=COUNT:#
    #   -b=COUNT:$
    #   -c=COUNT:a,b,c
    #   -e=DIR:DIRPATH
    #   -f=FILE:FILEPATH
    #
    #
    # Special constants
    #
    #           Exist   Missing   Optional
    #
    #   File    FILE    -         FILEPATH
    #   Dir     DIR     -         DIRPATH
    #   Node    NODE    NEW       PATH
    #

    class Option < Node
      def parse
        token.source =~ /^(-|--|\+|\+\+)([a-zA-Z0-9_,][a-zA-Z0-9_,-]*)(?:=(.+?)(\?)?)?$/ or 
            raise "Illegal option: #{token.source.inspect}"
        initial = $1
        names = $2.split(",")
        arg = $3
        optional = $4

        @repeatable = %w(+ ++).include?(initial)

        @short_names = []
        if %(- +).include?(initial)
          while names.first&.size == 1
            @short_names << names.shift
          end
        end
        @long_names = names
        @name = @long_names.first || @short_names.first
        @argument = !arg.nil?

        named = true
        if @argument
          if arg =~ /^([^:]+)(?::(.*))/
            @argument_name = $1
            named = true
            arg = $2
          elsif arg =~ /^:(.*)/
            arg = $1
            named = false
          end

          case arg
            when "", nil
              @argument_name ||= "VAL"
              @argument_type = ArgumentType.new
            when "#"
              @argument_name ||= "INT"
              @argument_type = IntegerArgument.new
            when "$"
              @argument_name ||= "NUM"
              @argument_type = FloatArgument.new
            when "FILE", "DIR", "NODE", "FILEPATH", "DIRPATH", "PATH", "NEW"
              @argument_name ||= %w(FILE DIR).include?(arg) ? arg : "PATH"
              @argument_type = FileArgument.new(@argument_name.downcase.to_sym)
            when /,/
              @argument_name ||= arg
              @argument_type = EnumArgument.new(arg.split(","))
            else
              named && @argument_name.nil? or raise ParserError, "Illegal type expression: #{arg.inspect}"
              @argument_name = arg
              @argument_type = ArgumentType.new
          end
          @optional = !optional.nil?
        else
          @argument_type = ArgumentType.new
        end
      end
    end

    class Command < Node
      def parse
        @path = token.to_s.sub("!", "")
        @name = @path.split(".").last
      end
    end

    class Program < Command
      def self.parse(token)
        super(nil, token)
      end
    end

    class Arguments < Node
      def parse # TODO
        super
      end
    end
  end

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

