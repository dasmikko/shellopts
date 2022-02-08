module ShellOpts
  module Grammar
    class Parser
      def self.parse(program_name, exprs)
        @commands = []
        @commands << (@current = @cmd = Program.new(program_name))
        @exprs = exprs.dup

        while !@exprs.empty?
          type, value = @exprs.shift
          case type
            when "OPT"
              parse_option(value)
            when "CMD"
              parse_command(value)
            when "ARG"
              parse_argument(value)
            when "TXT"
              parse_text(value)
          else
            raise
          end
        end

        @commands.each { |cmd| # Remove empty last-lines in comments and options
          while cmd.text.last =~ /^\s*$/
            cmd.text.pop
          end
          cmd.opts.each { |opt|
            while opt.text.last =~ /^\s*$/
              opt.text.pop
            end
          }
        }

        @commands
      end

      def self.parse_option_names(names)
        names.split(",")
      end

      def self.parse_option(source)
        OPTION_RE =~ source or raise CompilerError, "Illegal option: #{source}"
        option_group = $1
        argument = $4 || $2 && true
        type = $3
        optional = $5

        option_group =~ /^(\+\+?|--?)(.*)/
        repeatable = ($1 == '+' || $1 == '++' ? '+' : nil)
        names = parse_option_names($2)

        @cmd.opts << (@current = Option.new(
            names, 
            repeatable: repeatable, argument: argument, 
            integer: (type == '#'), float: (type == '$'),
            optional: optional))
        !OPTION_RESERVED_WORDS.include?(@current.name) or 
            raise CompilerError, "Reserved option name: #{@current.name}"
      end

      def self.parse_argument(source)
        @cmd.args << source
      end

      def self.parse_command(value)
        @commands << (@current = @cmd = Command.new(value))
        !COMMAND_RESERVED_WORDS.include?(@current.name) or
            raise CompilerError, "Reserved command name: #{@current.name}"
      end

      def self.parse_text(value)
        @current.text << value
      end
    end
  end
end
