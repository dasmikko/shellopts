
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
    #   -a=               # Renders as -a=
    #   -a=#              # Renders as -a=INT
    #   -b=$              # Renders as -b=NUM
    #   -c=a,b,c          # Renders as -c=a|b|c
    #   -d=3..5           # Renders as -d=3..5
    #   -e=:DIR           # Renders as -e=DIR
    #   -f=:FILE          # Renders as -f=FILE
    #
    #   -o=COUNT          
    #   -a=COUNT:#
    #   -b=COUNT:$
    #   -c=COUNT:a,b,c
    #   -e=DIR:DIRPATH
    #   -f=FILE:FILEPATH
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
        token.source =~ /^(-|--|\+|\+\+)([a-zA-Z0-9][a-zA-Z0-9_,-]*)(?:=(.+?)(\?)?)?$/ or 
            raise ParserError, "Illegal option: #{token.source.inspect}"
        initial = $1
        names = $2
        arg = $3
        optional = $4

        @repeatable = %w(+ ++).include?(initial)

        names = names.split(",").map { |name| name.sub("-", "_") }
        @short_names = []
        if %(- +).include?(initial)
          while names.first&.size == 1
            @short_names << names.shift
          end
        end
        @long_names = names
        @name = @long_names.first || @short_names.first
        @ident = ::ShellOpts::Expr::Command::RESERVED_OPTION_NAMES.include?(name) ? nil : name.to_sym
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

    class Spec < Node
      def parse # TODO
        super
      end
    end
  end

  class Parser
    include Grammar
    using Stack
    using Ext::Array::ShiftWhile

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

        case token.kind
          when :option
            if !nodes.top.is_a?(OptionGroup) # Ensure a token group at the top of the stack
              nodes.push OptionGroup.new(nodes.top, token)
            end
            Grammar::Option.parse(nodes.top, token)

          when :command
            nodes.push Command.parse(nodes.top, token)

          when :spec
            nodes.push Command.parse(nodes.top, token)

          when :argument
            Argument.parse(nodes.top, token)

          when :usage
            Usage.parse(nodes.top, token)

          when :text
            # Detect nested comment groups (code)
            if nodes.top.is_a?(Paragraph)
              code = Code.parse(nodes.top.parent, token) # Using parent of paragraph
              tokens.unshift token
              while token = tokens.shift
                if token.kind == :text && token.char >= code.token.char
                  Text.parse(code, token)
                elsif token.kind == :blank
                  Text.parse(code, token) if tokens.first.kind == :doc && tokens.first.char >= code.token.char
                else
                  tokens.unshift token
                  break
                end
              end

            # Detect comment groups (paragraphs)
            else
              paragraph = Paragraph.parse(nodes.top, token)
              tokens.unshift token
              while tokens.first.kind == :text && tokens.first.char == paragraph.token.char
                Text.parse(paragraph, tokens.shift)
              end
              nodes.push paragraph # Leave paragraph on stack so we can detect code blocks
            end

          when :brief
            Brief.parse(nodes.top, token)

          when :blank
            ; # do nothing

        else
          raise InternalError, "Unexpected token kind: #{token.kind.inspect}"
        end

        # Create default node
#       elsif token.kind != :blank
#         nodes.push eval("Grammar::#{token.kind.capitalize}").parse(nodes.top, token)

        # Skip blank lines
        tokens.shift_while { |token| token.kind == :blank }
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

