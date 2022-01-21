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

      def traverse(*klasses, &block)
        do_traverse(Array(klasses).flatten, &block)
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

      # Symbolic identifier. This is the canonical name of the option with
      # dashes replaced with underscores. It is only defined if it doesn't
      # clash with the enclosing command's member methods.
      attr_reader :ident

      # Canonical name. This is the name of the first long option or the name
      # of the first short option if there is no long option name. It is also
      # used to compute #ident
      attr_reader :name

      # Short option names
      attr_reader :short_names

      # Long option names
      attr_reader :long_names

      # Names of option. Includes both short and long option names
      def names() @names = short_names + long_names end

      # Name of argument or nil if not present
      attr_reader :argument_name

      # Value argument_type. An OptionConstraint object
      attr_reader :argument_type

      # Brief description (a String)
      attr_accessor :brief

      def repeatable?() @repeatable end
      def argument?() @argument end
      def integer?() @argument_type.is_a? IntegerConstraint end
      def float?() @argument_type.is_a? FloatConstraint end
      def file?() @argument_type.is_a? FileConstraint end
      def enum?() @argument_type.is_a? EnumConstraint end
      def string?() argument? !integer? && !float? && !file? && !enums? end
      def optional?() @optional end

      def match?(value) argument_type.match?(value) end

      def initialize(parent, token)
        super(parent, token)
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
      # Command identifier (incl. the exclamation mark)
      def ident() "#{name}!".to_sym end

      # Name of command without the exclamation mark. String
      attr_reader :name

      # Path of command
      attr_reader :path

      # Array of options in declaration order (initialized by the analyzer)
      attr_reader :options

      # Array of sub-commands (initialized by the analyzer)
      attr_reader :commands

      # Array of argument specifications
      attr_reader :arguments

      # Brief description of command (a String)
      attr_accessor :brief

      def initialize(parent, token)
        super
        @options = []
        @options_hash = {}
        @commands = []
        @commands_hash = {}
        @arguments = []
      end

      # Maps from any name of an option or command (incl. the '!') to the
      # associated option. Names can be a Symbol or String objects
      def [](name) (name.to_s =~ /!$/ ? @commands_hash : @options_hash)[name] end
      def key?(name) (name.to_s =~ /!$/ ? @commands_hash : @options_hash).key?(name) end

      def dump_command
        puts name
        indent { 
          puts "brief: #{brief.text.inspect}" if brief
          puts "options:" if !options.empty?
          indent { options.each { |option| puts option.name_list } }
          puts "commands:" if !commands.empty?
          indent { commands.each(&:dump_command) }
          puts "arguments:" if !arguments.empty?
          indent { puts arguments.map { |args| args.token.source } }
        }
      end
    end

    class Program < Command
      def dump_source() "" end
    end

    class Spec < Node
    end

    class Arg < Node
    end

    class Usage < Node
    end

    class Brief < Node
      attr_reader :text

      def parse
        @text = token.source.sub(/^#\s*/, "")
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

    class Doc < Node
    end
  end
end

__END__
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

    class OptionConstraint
      def source() end
      def to_s() end
      def convert(value) value end
    end

    class IntegerConstraint < OptionConstraint
      def match?(value) value.is_a?(Integer) end
      def convert(value) value.to_i end
    end

    class FloatConstraint < OptionConstraint
      def match?(value) value.is_a?(Number) end
      def convert(value) value.to_f end
    end

    class FileSystemConstraint < OptionConstraint
      attr_reader :kind # :file, :dir, :node, :filepath, :dirpath, :path, :new
      def initialize(kind) 
        @kind = kind 
      end
      def match?(value)
        case kind
          when :file; File.file?(value)
          when :dir; File.directory?(value)
          when :node; File.exist?(value)
          when :filepath; File.file?(value) || File.exist?(File.dirname(value))
          when :dirpath; File.directory?(value) || File.exist?(File.dirname(value))
          when :path; File.exist?(value) || File.exist?(File.dirname(value))
        else
          raise InternalError, "Illegal kind: #{kind.inspect}"
        end
      end
    end

    class EnumConstraint < OptionConstraint
      attr_reader :values
      def initialize(values) @values = values.dup end
      def match?(value) values.include?(value) end
    end

