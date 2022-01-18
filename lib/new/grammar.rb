module ShellOpts
  module Grammar
    class Node
      attr_reader :parent
      attr_reader :children
      attr_reader :token

      def initialize(parent, token)
        constrain parent, Node, nil
        constrain token, Token

        @parent = parent
        @children = []
        @token = token
        @parent.children << self if @parent
      end

      def parse
        self
      end

      def self.parse(parent, token)
        self.new(parent, token).parse
      end

      def dump
        puts "#{self.class} @ #{token.pos} #{dump_source}"
        indent { children.each(&:dump) }
      end

      def dump_source() token.source.inspect end

    protected
      def err(message)
        raise CompilerError, "#{token.pos} #{message}"
      end
    end

    class Option < Node
      def command() parent.parent end

      # Canonical name. nil if collision with reserved option name
      attr_reader :name

      # Short option names
      attr_reader :short_names

      # Long option names
      attr_reader :long_names

      def initialize(parent, token)
        # parse option and set name
        name = "Not yet"
        super(parent, token)
      end

      def parse
        @name = token.to_s.sub(/^-+([^,]+).*/, '\1')
        @short_names = (@name.size == 1 ? [name] : [])
        @long_names = (@name.size > 1 ? [name] : [])
        self
      end
    end

    class OptionGroup < Node
      alias_method :command, :parent

      attr_reader :brief
      attr_reader :description

      def initialize(parent, token)
        super(parent, token)
      end

      def dump_source() "" end
    end

    class Command < Node
      # Name of command
      attr_reader :name

      # Path of command
      attr_reader :path

      # Options (initialized by the analyzer)
      attr_reader :options

      attr_reader :brief
      attr_reader :description 

      def parse
        @path = token.to_s.sub("!", "")
        @name = @path.split(".").last
        @options = []
        self
      end
    end

    class Program < Command
      def initialize(token, name = $PROGRAM_NAME)
        @name = name
        super(nil, token)
      end

      def parse() 
        @path = name 
        self
      end

      def dump_source() "" end
    end

    class Arguments < Node
    end

    class Paragraph < Node
      def dump_source() "" end
      def text() @text ||= children.map { |line| line.source }.join(" ") end
    end

    class Code < Paragraph
      def text()
        indent = token.char
        children.map { |line| " " * (line.token.char - indent) + line.token.source }.join("\n") 
      end
    end

    class Line < Node
    end

    class Brief < Line
    end

    class Blank < Line
    end
  end
end
