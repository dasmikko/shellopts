module ShellOpts
  module Grammar
    # Program is the root object of the grammar
    class Program < Command
      # Array of non-option litteral arguments (ie. what comes after the double dash ('+--+') in
      # the usage definition). Initially empty but filled out during compilation
      attr_reader :args

      # Initialize a top-level Program object
      def initialize(name, option_list)
        super(nil, name, option_list)
        @args = []
      end

      # Usage string to be used in error messages. The string is kept short by
      # only listing the shortest option (if there is more than one)
      def usage
        (
          render_options(option_list) + 
          command_list.map { |cmd| render_command(cmd) } + 
          args
        ).flatten.join(" ")
      end

      # :nocov:
      def dump(&block)
        super { 
          puts "args: #{args.inspect}" 
          puts "usage: #{usage.inspect}"
        }
      end
      # :nocov:

    private
      def render_command(command)
        [command.name] + render_options(command.option_list) + 
            command.command_list.map { |cmd| render_command(cmd) }.flatten
      end

      def render_options(options)
        options.map { |opt|
          s = opt.names.first
          if opt.argument?
            arg_string = 
                if opt.label
                  opt.label
                elsif opt.integer?
                  "INT"
                elsif opt.float?
                  "FLOAT"
                else
                  "ARG"
                end
            if opt.optional?
              s += "[=#{arg_string}]"
            else
              s += "=#{arg_string}"
            end
          end
          s
        }
      end
    end
  end
end
