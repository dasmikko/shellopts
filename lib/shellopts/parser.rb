
module ShellOpts
  module Grammar
    class Node
      def parse() end

      def self.parse(parent, token)
        this = self.new(parent, token)
        this.parse
        this
      end

      def parser_error(token, message) raise ParserError, "#{token.pos} #{message}" end
    end

    class IdrNode < Node
      # Assume @ident and @name has been defined
      def parse
        @attr = ::ShellOpts::Command::RESERVED_OPTION_NAMES.include?(ident.to_s) ? nil : ident
        @path = (command&.path || []) + [ident]
        @uid = @path.join(".")
      end
    end

    class Option < IdrNode
      SHORT_NAME_RE = /[a-zA-Z0-9]/
      LONG_NAME_RE = /[a-zA-Z0-9][a-zA-Z0-9_-]*/
      NAME_RE = /(?:#{SHORT_NAME_RE}|#{LONG_NAME_RE})(?:,#{LONG_NAME_RE})*/

      def parse
        token.source =~ /^(-|--|\+|\+\+)(#{NAME_RE})(?:=(.+?)(\?)?)?$/ or 
            parser_error token, "Illegal option: #{token.source.inspect}"
        initial = $1
        name_list = $2
        arg = $3
        optional = $4

        @repeatable = %w(+ ++).include?(initial)

        @short_idents = []
        @short_names = []
        names = name_list.split(",")
        if %w(+ -).include?(initial)
          while names.first&.size == 1
            name = names.shift
            @short_names << "-#{name}"
            @short_idents << name.to_sym
          end
        end
        @long_names = names.map { |name| "--#{name}" }
        @long_idents = names.map { |name| name.tr("-", "_").to_sym }

        @name = @long_names.first || @short_names.first
        @ident = @long_idents.first || @short_idents.first

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
              @argument_type = StringType.new
            when "#"
              @argument_name ||= "INT"
              @argument_type = IntegerArgument.new
            when "$"
              @argument_name ||= "NUM"
              @argument_type = FloatArgument.new
            when "FILE", "DIR", "PATH", "EFILE", "EDIR", "EPATH", "NFILE", "NDIR", "NPATH"
              @argument_name ||= arg.sub(/^(?:E|N)/, "")
              @argument_type = FileArgument.new(arg.downcase.to_sym)
            when /,/
              @argument_name ||= arg
              @argument_type = EnumArgument.new(arg.split(","))
            else
              named && @argument_name.nil? or parser_error token, "Illegal type expression: #{arg.inspect}"
              @argument_name = arg
              @argument_type = StringType.new
          end
          @optional = !optional.nil?
        else
          @argument_type = StringType.new
        end
        super
      end

    private
      def basename2ident(s) s.tr("-", "_").to_sym end
    end

    class Command < IdrNode
      def parse
        @name = token.source.split(".").last.sub(/^!/, "")
        @ident = "#{@name}!".to_sym
        super
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
#   include Grammar
    using Stack
    using Ext::Array::ShiftWhile

    # Array of token
    attr_reader :tokens

    # AST root node
    attr_reader :program

    def initialize(tokens)
      @tokens = tokens.dup
    end

    def parse()
      @program = Grammar::Program.parse(tokens.shift)
      nodes = [@program] # Stack of Nodes. Follows the indentation of the source
      commands = [@program] # Stack of commands. Used to keep track of the curren command

      while token = tokens.shift
        while token.char <= nodes.top.token.char
          node = nodes.pop
          commands.pop if commands.top == node
          !nodes.empty? or err(token, "Illegal indent")
        end

        case token.kind
          when :option
            if !nodes.top.is_a?(Grammar::OptionGroup) # Ensure a token group at the top of the stack
              nodes.push Grammar::OptionGroup.new(commands.top, token)
            end
            Grammar::Option.parse(nodes.top, token)

          when :command
            command = Grammar::Command.parse(commands.top, token)
            nodes.push command
            commands.push command

          when :spec
            nodes.push Grammar::Spec.parse(commands.top, token)

          when :argument
            Grammar::Argument.parse(nodes.top, token)

          when :usage
            nodes.push Grammar::Usage.parse(commands.top, token)

          when :text
            # Detect indented comment groups (code)
            if nodes.top.is_a?(Grammar::Paragraph)
              code = Grammar::Code.parse(nodes.top.parent, token) # Using parent of paragraph
              tokens.unshift token
              while token = tokens.shift
                if token.kind == :text && token.char >= code.token.char
                  Grammar::Text.parse(code, token)
                elsif token.kind == :blank
                  Grammar::Text.parse(code, token) \
                      if tokens.first.kind == :text && tokens.first.char >= code.token.char
                else
                  tokens.unshift token
                  break
                end
              end

            # Detect comment groups (paragraphs)
            else
              if nodes.top.is_a?(Grammar::Command) || nodes.top.is_a?(Grammar::OptionGroup)
                parent = nodes.top 
              else
                parent = nodes.top.parent
              end
              paragraph = Grammar::Paragraph.parse(parent, token)
              tokens.unshift token
              while tokens.first && tokens.first.kind == :text && tokens.first.char == paragraph.token.char
                Grammar::Text.parse(paragraph, tokens.shift)
              end
              nodes.push paragraph # Leave paragraph on stack so we can detect code blocks
            end

          when :brief
            parent = nodes.top.is_a?(Grammar::Paragraph) ? nodes.top.parent : nodes.top
            Grammar::Brief.parse(parent, token)

          when :blank
            ; # do nothing

        else
          raise InternalError, "Unexpected token kind: #{token.kind.inspect}"
        end

        # Skip blank lines
        tokens.shift_while { |token| token.kind == :blank }
      end

      @program
    end

    def self.parse(tokens)
      self.new(tokens).parse
    end
  end
end

