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
        yield(self) if klasses.empty? || klasses.any? { |klass| self.is_a?(klass) }
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

    # Note that options are children of Command object but are attached to
    # OptionGroup objects that in turn are attached to the command. This is
    # done to be able to handle multiple options with common brief or
    # descriptions
    #
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
      def names() short_names + long_names end # TODO: Should be in declaration order

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

      # Brief description of option(s). Assigned by #attach
      attr_reader :brief

      # Description of option(s). Array of Paragraph or Code objects. Assigned
      # by #attach
      attr_reader :description

      def initialize(parent, token)
        super(parent, token)
        @options = []
        @brief = nil
        @description = []
      end

    protected
      def attach(child)
        super
        case child
          when Option; @options << child
          when Brief; @brief = child
          when Paragraph, Code; @description << child
        end
      end
    end

    class Command < IdrNode
      # Brief description of command. Assigned to by #attach
      attr_accessor :brief

      # Description of command. Array of Paragraph or Code objects. Assigned by
      # #attach
      attr_reader :description

      attr_reader :options_description
      attr_reader :commands_description

      # Array of option groups in declaration order. Assigned to by
      # #attach. TODO: Rename 'groups'
      attr_reader :option_groups

      # Array of options in declaration order. Assigned to by the analyzer
      attr_reader :options

      # Array of sub-commands. Assigned to by #attach
      attr_reader :commands

      # Arg specification objects. Assigned to by #attach
      attr_reader :specs

      # ArgDescr(s) if present. Assigned to by #attach
      attr_reader :descrs

      def initialize(parent, token)
        super
        @brief = nil
        @description = []
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
        case child
          when OptionGroup; @option_groups << child
          when Command; @commands << child
          when ArgSpec; @specs << child
          when ArgDescr; @descrs << child
          when Brief; @brief = child
          when Paragraph, Code; @description << child
        end
      end
    end

    class Program < Command
      # Lifted from .gemspec. TODO
      attr_reader :info

      # Shorthand to get the associated Grammar::Program object from a Program
      # object
      def self.program(obj)
        constrain obj, Program, ::ShellOpts::Program
        obj.is_a?(Program) || obj.__grammar__
      end
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
      def lines() [text] end

      def to_s() text end # FIXME

      def initialize(parent, token)
        super
        @tokens = [token]
      end
    end

    class ArgDescr < DocNode
      alias_method :command, :parent
    end

    module WrappedNode
      using Ext::Array::Wrap
      def words() @words ||= text.split(" ") end
      def lines(width, initial = 0) @lines ||= words.wrap(width, initial) end
    end

    class Brief < DocNode
      include WrappedNode
      alias_method :subject, :parent # Either a command or an option
    end

    class Paragraph < DocNode
      include WrappedNode
      alias_method :subject, :parent # Either a command or an option
    end

    class Code < DocNode
      def text() @text ||= lines.join("\n") end
      def lines() @lines ||= tokens.map { |t| " " * (t.char - token.char) + t.source } end
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

