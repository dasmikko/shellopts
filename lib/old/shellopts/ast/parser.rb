module ShellOpts
  module Ast
    # Parse a subcommand
    class Parser
      def initialize(grammar, argv)
        @grammar, @argv = grammar, argv.dup
        @seen_options = {} # Used to keep track of repeated options
        @current = nil # Current command
      end

      def call
        @current = program = Program.new(@grammar)
        parse_command(program)
        cmd = Command.grammar(@current)
        !cmd.virtual? or error("'%s' command requires a sub-command")
        [program, Args.new(cmd, @argv)]
      end

      def self.parse(grammar, argv)
        self.new(grammar, argv).call
      end

    private
      def error(message)
        grammar = Command.grammar(@current)
        raise Error.new(grammar), message % grammar.name
      end

      def parse_command(command)
        @seen_options = {} # Every new command resets the seen options
        while arg = @argv.first
          if arg == "--"
            @argv.shift
            break
          elsif arg.start_with?("-")
            parse_option(command)
          elsif cmd = Command.grammar(command).commands[arg]
            @argv.shift
            @current = subcommand = Ast::Command.new(cmd)
            Command.add_command(command, subcommand)
            parse_command(subcommand)
            break
          else
            break
          end
        end
      end

      def parse_option(command)
        # Split into name and argument
        case @argv.first
          when /^--(.+?)(?:=(.*))?$/
            name, arg, short = $1, $2, false
            opt_name = "--#{name}"
          when /^-(.)(.+)?$/
            name, arg, short = $1, $2, true
            opt_name = "-#{name}"
        end
        @argv.shift

        option = Command.grammar(command).options[name] or error "Unknown option '#{opt_name}'"
        !@seen_options.key?(option.ident) || option.repeatable? or error "Duplicate option '#{opt_name}'"
        @seen_options[option.ident] = true

        # Parse (optional) argument
        if option.argument?
          if arg.nil? && !option.optional?
            if !@argv.empty?
              arg = @argv.shift
            else
              error "Missing argument for option '#{opt_name}'"
            end
          end
          arg &&= parse_option_arg(option, name, arg)
        elsif arg && short
          @argv.unshift("-#{arg}")
          arg = nil
        elsif !arg.nil?
          error "No argument allowed for option '#{opt_name}'"
        end
        
        Command.add_option(command, Option.new(option, name, arg))
      end

      def parse_option_arg(option, name, arg)
        if option.string?
          arg
        elsif arg == ""
          nil
        elsif option.integer?
          arg =~ /^-?\d+$/ or error "Illegal integer in '#{name}' argument: '#{arg}'"
          arg.to_i
        elsif # option.float?
          # https://stackoverflow.com/a/21891705/2130986
          arg =~ /^[+-]?(?:0|[1-9]\d*)(?:\.(?:\d*[1-9]|0))?$/ or
              error "Illegal float in '#{name}' argument: '#{arg}'"
          arg.to_f
        else
          raise ArgumentError
        end
      end
    end
  end
end

