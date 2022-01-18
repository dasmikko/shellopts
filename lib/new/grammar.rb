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

      # Return list of nodes in preorder or execute block on each node
      def preorder(include_self: true, &block)
        if block_given?
          yield(self) if include_self
          children.each { |e| e.preorder(include_self: include_self, &block) }
        else
          (include_self ? [self] : []) + 
              children.inject([]) { |a,e| a + e.preorder(include_self: include_self) }
        end
      end

      # Return list of nodes in postorder. If block given execute block on each node
      def postorder(&block)
        if block_given?
          children.each { |e| e.postorder(include_self: include_self, &block) }
          yield(self) if include_self
        else
          children.inject([]) { |a,e| a + e.postorder(include_self: include_self) } +
              (include_self ? [self] : [])
        end
      end

      def traverse(*klasses, &block)
        do_traverse(Array(klasses).flatten, &block)
      end

      def link(command)
        children.each { |node| node.link(command) }
      end

      def parse
        self
      end

      def self.parse(parent, token)
        this = self.new(parent, token)
        this.parse
        this
      end

      def dump
        puts "#{self.class} @ #{token.pos} #{dump_source}"
        indent { children.each(&:dump) }
      end

      def dump_source() token.source.inspect end

    protected
      def do_traverse(klasses, &block)
        yield(self) if klasses.any? { |klass| self.is_a?(klass) }
        children.each { |node| node.traverse(klasses, &block) }
      end

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

      def link(command)
        command.options << self
      end

      def name_list
        (short_names.map { |name| "-#{name}" } + long_names.map { |name| "--#{name}" }).join(", ")
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

      # Array of options (initialized by the analyzer)
      attr_reader :options

      # Array of sub-commands (initialized by the analyzer)
      attr_reader :commands

      # Array of argument specifications
      attr_reader :arguments

      attr_reader :brief
      attr_reader :description 

      def initialize(parent, token)
        super
        @options = []
        @commands = []
        @arguments = []
      end

      def parse
        @path = token.to_s.sub("!", "")
        @name = @path.split(".").last
        self
      end

      def link(command = nil)
        command.commands << self if command
        children.each { |node| node.link(self) }
      end

      def dump_command
        puts name
        indent { 
          puts "Options" if !options.empty?
          indent { options.each { |option| puts option.name_list } }
          puts "Commands" if !commands.empty?
          indent { commands.each(&:dump_command) }
          puts "Arguments" if !arguments.empty?
          indent { puts arguments.map { |args| args.token.source } }
        }
      end
    end

    class Program < Command
      def self.parse(token)
        super(nil, token)
      end

      def dump_source() "" end
    end

    class Arguments < Node
      def link(command)
        command.arguments << self
      end
    end

    class Paragraph < Node
      def text() @text ||= children.map { |line| line.source }.join(" ") end
      def dump_source() "" end
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
