module ShellOpts
  module Grammar
    # TODO: Command aliases: list.something!,list.somethingelse!
    class Command
      # Parent command. nil for the program-level Command object. Initialized
      # by the analyzer
      attr_reader :parent

      # Name of command. nil for the program-level Command object
      attr_reader :name

      # Ident of command. nil for the program-level Command object
      attr_reader :ident

      # Path of command. The empty string for the program-level Command object
      attr_reader :path

      # Path of parent command. nil for the program-level Command object. This
      # is the same as #parent&.path but is available before #parent is
      # intialized. It is used to build the command hierarchy in the analyzer
      attr_reader :parent_path

      # List of comments. Initialized by the parser
      attr_reader :text 

      # List of options. Initialized by the parser
      attr_reader :opts 

      # List of sub-commands. Initialized by the parser
      attr_reader :cmds 

      # List of arguments. Initialized by the parser
      attr_reader :args

      # Hash from name/identifier to option. Note that each option has at least
      # two entries in the hash: One by name and one by identifier. Option
      # aliases are also keys in the hash. Initialized by the analyzer
      attr_reader :options 

      # Hash from name to sub-command. Note that each command has two entries in
      # the hash: One by name and one by identifier. Initialized by the analyzer
      attr_reader :commands 

      def initialize(path, virtual: false)
        if path == ""
          @path = path
        else
          @path = path.sub(/!$/, "")
          components = @path.split(".")
          @name = components.pop
          @parent_path = components.join(".")
          @ident = @name.gsub(/-/, "_").to_sym
        end
        @virtual = virtual
        @text = []
        @opts = []
        @cmds = []
        @args = []

        @options = {}
        @commands = {}
      end

      # True if this is the program-level command
      def program?() @path == "" end

      # True if this is a virtual command that cannot be called without a
      # sub-command
      def virtual?() @virtual end

      def <=>(other)
        path <=> other.path
      end
    end

    class Program < Command
      def initialize(name) 
        super("") 
        @name = name
      end
    end

    class VirtualCommand < Command
      def initialize(path) super(path, virtual: true) end
    end
  end
end
