module ShellOpts
  module Grammar
    # A command. Commands are organized hierarchically with a Program object as
    # the root node
    #
    # Sets Node#key to the name of the command incl. the exclamation point
    class Command < Node
      # Parent command. Nil if this is the top level command (the program)
      attr_reader :parent

      # Name of command (String). Name doesn't include the exclamation point ('!')
      attr_reader :name

      # Same as #name. TODO Define in Grammar::Node instead
      alias :key_name :name

      # List of options in declaration order
      attr_reader :option_list

      # List of commands in declaration order
      attr_reader :subcommand_list

      # Multihash from option key or names (both short and long names) to option. This
      # means an option can occur more than once as the hash value
      def options() 
        @option_multihash ||= @option_list.flat_map { |option| 
          option.identifiers.map { |ident| [ident, option] }
        }.to_h
      end

      # Sub-commands of this command. Is a multihash from sub-command key or
      # name to command object. Lazily constructed because subcommands are added
      # after initialization
      def subcommands()
        @subcommand_multihash ||= @subcommand_list.flat_map { |subcommand| 
          subcommand.identifiers.map { |name| [name, subcommand] }
        }.to_h
      end

      # Initialize a Command object. parent is the parent Command object or nil
      # if this is the root object. name is the name of the command (without
      # the exclamation mark), and option_list a list of Option objects
      def initialize(parent, name, option_list)
        super("#{name}!".to_sym, name)
        parent.attach(self) if parent
        @option_list = option_list
        @subcommand_list = []
      end

      # Return key for the identifier
      def identifier2key(ident)
        options[ident]&.key || subcommands[ident]&.key
      end

      # Return list of identifiers for the command
      def identifiers() [key, name] end

      # :nocov:
      def dump(&block)
        puts "#{key.inspect}"
        indent {
          puts "parent: #{parent&.key.inspect}"
          puts "name: #{name.inspect}"
          yield if block_given?
          puts "options:"
          indent { option_list.each { |opt| opt.dump } }
          puts "subcommands: "
          indent { subcommand_list.each { |cmd| cmd.dump } }
        }
      end
      # :nocov:

    protected
      def attach(subcommand)
        subcommand.instance_variable_set(:@parent, self)
        @subcommand_list << subcommand
      end
    end
  end
end
