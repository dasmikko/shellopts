module ShellOpts
  module Grammar
    # Except for parent, children, and token, all members are initialized by calling
    # #parse on the object
    class Node
      attr_reader :parent
      attr_reader :children
      attr_reader :token

      def initialize(parent, token)
        constrain parent, Node, nil
        constrain parent, lambda { |node| ALLOWED_PARENTS[self.class].any? { |klass| node.is_a?(klass) } }
        constrain token, Token

        @parent = parent
        @children = []
        @token = token
        @parent.send(:attach, self) if @parent
      end

      def traverse(*klasses, &block)
        do_traverse(Array(klasses).flatten, &block)
      end

    protected
      def attach(child)
        @children << child
      end

      def do_traverse(klasses, &block)
        yield(self) if klasses.any? { |klass| self.is_a?(klass) }
        children.each { |node| node.traverse(klasses, &block) }
      end

      def err(message)
        raise CompilerError, "#{token.pos} #{message}"
      end
    end

    class Option < Node
      # Command of this object
      def command() parent.parent end # double-parent because options live in option groups

      # Option group of this object
      def group() parent end

      # Symbolic identifier. This is the canonical name of the option with
      # dashes replaced with underscores. It is only defined if it doesn't
      # clash with the enclosing command's member methods.
      attr_reader :ident

      # Canonical name. This is the name of the first long option or the name
      # of the first short option if there is no long option name. It is also
      # used to compute #ident
      attr_reader :name

      # Short option identfiers. This is the short names of the option as
      # symbols and without the initial '-'
      attr_reader :short_idents

      # Long option identifiers. This is the long names of the option without
      # the initial '--' and converted to symbols
      attr_reader :long_idents

      # Short option names (with '-')
      def short_names() @short_name ||= short_idents.map { |ident| "-#{ident}" } end

      # Long option names (with '--')
      def long_names() @long_name ||= long_idents.map { |ident| "-#{ident}" } end

      # Names of option. Includes both short and long option names. Note that
      # there is no corresponding #idents method because short and long
      # identifiers can contain duplicates
      def names() @names ||= short_names + long_names end

      # Name of argument or nil if not present
      attr_reader :argument_name

      # Type of argument (ArgumentType)
      attr_reader :argument_type

      # Enum values if argument type is an enumerator
      def argument_enum() @argument_type.values end

      # Brief description (a String). FIXME: This lives on the OptionGroup object
      attr_accessor :brief

      def repeatable?() @repeatable end
      def argument?() @argument end
      def integer?() @argument_type.is_a? IntegerArgument end
      def float?() @argument_type.is_a? FloatArgument end
      def file?() @argument_type.is_a? FileArgument end
      def enum?() @argument_type.is_a? EnumArgument end
      def string?() argument? && !integer? && !float? && !file? && !enum? end
      def optional?() @optional end

      def match?(value) argument_type.match?(value) end
    end

    class OptionGroup < Node
      alias_method :command, :parent

      attr_reader :brief
      attr_reader :description

      def initialize(parent, token)
        super(parent, token)
      end

    protected
      def attach(child)
        super
        command.options << child if child.is_a?(Option)
      end
    end

    class Command < Node
      alias_method :command, :parent

      # Command identifier
      def ident() "#{name}!".to_sym end

      # Name of command without the exclamation mark
      attr_reader :name

      # Path of command
      attr_reader :path

      # Brief description of command
      attr_accessor :brief

      # Array of options in declaration order
      attr_reader :options

      # Array of sub-commands
      attr_reader :commands

      # Argument specification objects
      attr_reader :specs

      # Usage(s) if present
      attr_reader :usages

      def initialize(parent, token)
        super
        @options = []
        @options_hash = {}
        @commands = []
        @commands_hash = {}
        @specs = []
        @usages = []
      end

      # Maps from any name of an option or command (incl. the '!') to the
      # associated option. Names can be a Symbol or String objects. #[] and
      # #key? can't be used until after the analyze phase
      def [](name) (name.to_s =~ /!$/ ? @commands_hash : options_hash)[name] end
      def key?(name) (name.to_s =~ /!$/ ? @commands_hash : options_hash).key?(name) end

    protected
      def attach(child)
        super
        # Check for duplicates happens in the analyze stage
        case child
          # Options are handled by the OptionGroup
          when Command; commands << child
          when Spec; specs << child
          when Usage; usages << child
          when Brief; @brief = brief
        end
      end
    end

    class Program < Command
    end

    class Spec < Node
      # List of Argument objects (initialized by the analyzer)
      alias_method :command, :parent

      attr_reader :arguments

      def initialize(parent, token)
        super
        @arguments = []
      end

    protected
      def attach(child)
        arguments << child if child.is_a?(Argument)
      end
    end

    class Argument < Node
      alias_method :spec, :parent
    end

    class Usage < Node
      alias_method :command, :parent
    end

    class DocNode < Node
      def text() @text ||= children.map { |line| line.source }.join(" ") end
      def to_s() @text end
    end

    class Brief < DocNode
      alias_method :subject, :parent # Either a command or an option

      def parse() @text = token.source.sub(/^#\s*/, "") end
    end

    # Aka. "a line"
    class Text < DocNode
    end

    class Blank < Text
    end

    class Paragraph < DocNode
      alias_method :command, :parent
    end

    class Code < Paragraph
      def text()
        @text ||= begin
          indent = token.char
          children.map { |line| " " * (line.token.char - indent) + line.token.source }.join("\n") 
        end
      end
    end

    class Node
      ALLOWED_PARENTS = {
        Program => [NilClass],
        Command => [Command],
        OptionGroup => [Command],
        Option => [OptionGroup],
        Spec => [Command],
        Argument => [Spec],
        Usage => [Command],
        Brief => [Command, OptionGroup, Spec, Usage],
        Paragraph => [Command, OptionGroup],
        Code => [Command, OptionGroup],
        Text => [Paragraph, Code],
        Blank => [Code]
      }
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
