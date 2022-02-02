module ShellOpts
  module Grammar
    # Except for #parent, #children, and #token, all members are initialized by calling
    # #parse on the object
    class Node
      attr_reader :parent
      attr_reader :children
      attr_reader :token

      def initialize(parent, token)
        constrain parent, Node, nil
        constrain parent, nil, lambda { |node| ALLOWED_PARENTS[self.class].any? { |klass| node.is_a?(klass) } }
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

    class IdrNode < Node
      # Command of this object
      alias_method :command, :parent

      # Unique identifier of node (String) within the context of a program. nil
      # for the Program object. It is the list of path elements concatenated
      # with '.'. Initialized by the parser
      attr_reader :uid

      # Path from Program object and down to this node. Array of identifiers.
      # Empty for the Program object. Initialized by the parser
      attr_reader :path

      # Canonical identifier (Symbol) of the object
      #
      # For options, this is the canonical name of the objekt without the
      # initial '-' or '--'. For commands it is the command name including the
      # suffixed exclamation mark. Both options and commands have internal dashes
      # replaced with underscores
      #
      # Note that an identifier can't be mapped back to a option name because
      # '--with-separator' and '--with_separator' both maps to :with_separator
      attr_reader :ident

      # Canonical name (String) of the object
      #
      # This is the name of the object as the user sees it. For options it is
      # the name of the first long option or the name of the first short option
      # if there is no long option name. For commands it is the name without
      # the exclamation mark
      attr_reader :name

      # The associated attribute (Symbol) in the parent command object. nil if
      # #ident is a reserved word
      attr_reader :attr
    end

    class Option < IdrNode
      # Redefine command of this object
      def command() parent.parent end # double-parent because options live in option groups

      # Option group of this object
      def group() parent end

      # Short option identfiers
      attr_reader :short_idents

      # Long option identifiers
      attr_reader :long_idents

      # Short option names (including initial '-')
      attr_reader :short_names

      # Long option names (including initial '--')
      attr_reader :long_names

      # Identifiers of option. Include both short and long identifiers
      def idents() short_idents + long_idents end

      # Names of option. Includes both short and long option names
      def names() short_names + long_names end

      # Name of argument or nil if not present
      attr_reader :argument_name

      # Type of argument (ArgumentType)
      attr_reader :argument_type

      # Enum values if argument type is an enumerator
      def argument_enum() @argument_type.values end

      def repeatable?() @repeatable end
      def argument?() @argument end
      def optional?() @optional end

      def integer?() @argument_type.is_a? IntegerArgument end
      def float?() @argument_type.is_a? FloatArgument end
      def file?() @argument_type.is_a? FileArgument end
      def enum?() @argument_type.is_a? EnumArgument end
      def string?() argument? && !integer? && !float? && !file? && !enum? end

      def match?(literal) argument_type.match?(literal) end

      # Return true if the option can be assigned the given value
#     def value?(value) ... end
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

    class Command < IdrNode
      # Brief description of command
      attr_accessor :brief

      # Array of options in declaration order
      attr_reader :options

      # Array of sub-commands
      attr_reader :commands

      # Argument specification objects
      attr_reader :specs

      # Usage(s) if present. FIXME: Rename to arguments
      attr_reader :usages

      def initialize(parent, token)
        super
        @options = []
        @options_hash = {} # Initialized by the analyzer
        @commands = []
        @commands_hash = {} # Initialized by the analyzer
        @specs = []
        @usages = []
      end

      # Maps from any name or identifier of an option or command (incl. the
      # '!') to the associated option. #[] and #key? can't be used until after
      # the analyze phase
      def [](key) @commands_hash[key] || @options_hash[key] end
      def key?(key) @commands_hash.key?(key) || @options_hash.key?(key) end

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

    class Spec < Node # FIXME: Rename to ArgSpec
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

    class Argument < Node # FIXME Rename to Arg else to avoid confusion with Arguments
      alias_method :spec, :parent
    end

    class Usage < Node # FIXME Rename to Arguments
      alias_method :command, :parent
      def source() token.source end
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

