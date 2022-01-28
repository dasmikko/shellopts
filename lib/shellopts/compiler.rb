
module ShellOpts
  class Compiler
    attr_reader :expr
    attr_reader :args

    def initialize(grammar, argv, float: true)
      constrain grammar, Grammar::Program
      constrain argv, [String]
      @grammar, @argv = grammar, argv.dup
      @float = float
    end

    def compile
      @expr = command = Expr::Command.new(@grammar)
      @seen = {} # Set of seen options by UID (using UID is needed when float is true)
      @args = []

      while arg = @argv.shift
        if arg == "--"
          break
        elsif arg.start_with?("-")
          compile_option(command, arg)
        elsif @args.empty? && subcommand_grammar = command.__grammar__[:"#{arg}!"]
          command = Expr::Command.add_command(command, Expr::Command.new(subcommand_grammar))
        else
          if @float
            @args << arg # This also signals that no more commands are accepted
          else
            @argv.unshift arg
            break
          end
        end
      end
      [@expr, @args += @argv]
    end

    def self.compile(grammar, argv)
      self.new(grammar, argv).compile
    end

  protected
    # Lookup option in the command hierarchy and return pair of command and
    # option associated command. Raise if not found
    #
    def find_option(command, name)
      while command && (option = command.__grammar__[name]).nil?
        command = command.__supercommand__
      end
      option or error "Unknown option '#{name}'"
      [command, option]
    end

    def compile_option(command, option)
      # Split into name and argument
      case option
        when /^(--.+?)(?:=(.*))?$/
          name, value, short = $1, $2, false
        when /^(-.)(.+)?$/
          name, value, short = $1, $2, true
      end

      option_command, option = find_option(command, name)
      !@seen.key?(option.uid) || option.repeatable? or error "Duplicate option '#{name}'"
      @seen[option.uid] = true

      # Process argument
      if option.argument?
        if value.nil? && !option.optional?
          if !@argv.empty?
            value = @argv.shift
          else
            error "Missing argument for option '#{name}'"
          end
        end
        value &&= compile_option_value(option, name, value)
      elsif value && short
        @argv.unshift("-#{value}")
        value = nil
      elsif !value.nil?
        error "No argument allowed for option '#{opt_name}'"
      end
      
      Expr::Command.add_option(option_command, Expr::UserOption.new(option, name, value))
    end

    def compile_option_value(option, name, value)
      type = option.valueument_type
      if type.match?(name, value)
        type.convert(value)
      elsif value == ""
        nil
      else
        error type.message
      end
    end

    def error(msg)
      raise CompilerError, msg
    end
  end
end

