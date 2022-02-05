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
      #
      # TODO: Should be in declaration order
      def names() short_names + long_names end

      # Name of argument or nil if not present
      attr_reader :argument_name

      # Type of argument (ArgType)
      attr_reader :argument_type

      # Enum values if argument type is an enumerator
      def argument_enum() @argument_type.values end

      def repeatable?() @repeatable end
      def argument?() @argument end
      def optional?() @optional end

      def integer?() @argument_type.is_a? IntegerArg end
      def float?() @argument_type.is_a? FloatArg end
      def file?() @argument_type.is_a? FileArg end
      def enum?() @argument_type.is_a? EnumArg end
      def string?() argument? && !integer? && !float? && !file? && !enum? end

      def match?(literal) argument_type.match?(literal) end

      # Return true if the option can be assigned the given value
#     def value?(value) ... end
    end

    class OptionGroup < Node
      alias_method :command, :parent

      # Array of options in declaration order. Assigned by #attach
      attr_reader :options

      attr_reader :brief
      attr_reader :description

      def initialize(parent, token)
        super(parent, token)
        @options = []
#       parent.option_groups << self # FIXME: Done twice? See Command#attach
      end

    protected
      def attach(child)
        super
        case child
          when Option
            @options << child
            command.options << child
          when Brief
            @brief = child
          # when Description
        end
      end
    end

    class Command < IdrNode
      # Brief description of command. Assigned to by #attach
      attr_accessor :brief

      # Array of option groups in declaration order. Assigned to by
      # #attach. TODO: Rename 'groups'
      attr_reader :option_groups

      # Array of options in declaration order. Assigned to by
      # OptionGroup#attach. FIXME: Or what? See OptionGroup#initialize and Command#attach
      attr_reader :options

      # Array of sub-commands. Assigned to by #attach
      attr_reader :commands

      # Arg specification objects. Assigned to by #attach
      attr_reader :specs

      # ArgDescr(s) if present. Assigned to by #attach
      attr_reader :descrs

      def initialize(parent, token)
        super
        @option_groups = []
        @options = []
        @options_hash = {} # Initialized by the analyzer
        @commands = []
        @commands_hash = {} # Initialized by the analyzer
        @specs = []
        @descrs = []
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
        #
        # FIXME: Need better separation or work between analyzer and #attach
        case child
          # Options are handled by the OptionGroup
          when OptionGroup; option_groups << child
          when Command; commands << child
          when ArgSpec; specs << child
          when ArgDescr; descrs << child
          when Brief; @brief = child
        end
      end
    end

    class Program < Command
    end

    class ArgSpec < Node
      # List of Arg objects (initialized by the analyzer)
      alias_method :command, :parent

      attr_reader :arguments

      def initialize(parent, token)
        super
        @arguments = []
      end

    protected
      def attach(child)
        arguments << child if child.is_a?(Arg)
      end
    end

    class Arg < Node
      alias_method :spec, :parent
    end

    # DocNode object has no children but lines
    class DocNode < Node
      attr_reader :tokens # :text tokens

      def text() @text ||= tokens.map(&:source).join(" ") end

      def to_s() text end # FIXME

      def initialize(parent, token)
        super
        @tokens = [token]
      end
    end

    class ArgDescr < DocNode
      alias_method :command, :parent
    end

    module Wrap
      def words() @words ||= text.split(" ") end
    end

    class Brief < DocNode
      include Wrap
      alias_method :subject, :parent # Either a command or an option
    end

    class Paragraph < DocNode
      include Wrap
      alias_method :subject, :parent # Either a command or an option
    end

    class Code < DocNode
      def text()
        @text ||= tokens.map { |t| " " * (t.char - token.char) + t.source }.join("\n")
      end
    end

    class Node
      ALLOWED_PARENTS = {
        Program => [NilClass],
        Command => [Command],
        OptionGroup => [Command],
        Option => [OptionGroup],
        ArgSpec => [Command],
        Arg => [ArgSpec],
        ArgDescr => [Command],
        Brief => [Command, OptionGroup, ArgSpec, ArgDescr],
        Paragraph => [Command, OptionGroup],
        Code => [Command, OptionGroup]
      }
    end
  end
end

