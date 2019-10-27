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

      # Hash from option names (both short and long names) to option. This
      # means an option can occur more than once as the hash value
      attr_reader :options 

      # Sub-commands of this command. Is a hash from sub-command name to command object
      attr_reader :commands 

      # List of options in declaration order
      attr_reader :option_list

      # List of commands in declaration order
      attr_reader :command_list

      # Initialize a Command object. parent is the parent Command object or nil
      # if this is the root object. name is the name of the command (without
      # the exclamation mark), and option_list a list of Option objects
      def initialize(parent, name, option_list)
        super("#{name}!".to_sym)
        @name = name
        parent.attach(self) if parent
        @option_list = option_list
        @options = @option_list.flat_map { |opt| opt.names.map { |name| [name, opt] } }.to_h
        @commands = {}
        @command_list = []
      end

      # :nocov:
      def dump(&block)
        puts "#{key.inspect}"
        indent {
          puts "parent: #{parent&.key.inspect}"
          puts "name: #{name.inspect}"
          yield if block_given?
          puts "options:"
          indent { option_list.each { |opt| opt.dump } }
          puts "commands: "
          indent { command_list.each { |cmd| cmd.dump } }
        }
      end
      # :nocov:

    protected
      def attach(command)
        command.instance_variable_set(:@parent, self)
        @commands[command.name] = command
        @command_list << command
      end
    end
  end
end
