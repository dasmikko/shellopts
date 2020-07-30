
require 'shellopts/ast/node.rb'
require 'shellopts/ast/option.rb'
require 'shellopts/ast/command.rb'
require 'shellopts/ast/program.rb'

module ShellOpts
  module Ast
    # Parse ARGV according to grammar. Returns a Ast::Program object
    def self.parse(grammar, argv)
      grammar.is_a?(Grammar::Program) or 
          raise InternalError, "Expected Grammar::Program object, got #{grammar.class}"
      argv.is_a?(Array) or
          raise InternalError, "Expected Array object, got #{argv.class}"
      Parser.new(grammar, argv).call
    end

  private
    # Parse a subcommand line
    class Parser
      class Error < RuntimeError; end

      def initialize(grammar, argv)
        @grammar, @argv = grammar, argv.dup
        @seen_options = {} # Used to keep track of repeated options
      end

      def call
        program = Ast::Program.new(@grammar)
        parse_subcommand(program)
        program.arguments = @argv
        program
      end

    private
      def parse_subcommand(subcommand)
        @seen_options = {} # Every new subcommand resets the seen options
        while arg = @argv.first
          if arg == "--"
            @argv.shift
            break
          elsif arg.start_with?("-")
            parse_option(subcommand)
          elsif cmd = subcommand.grammar.subcommands[arg]
            @argv.shift
            subcommand.subcommand = Ast::Command.new(cmd, arg)
            parse_subcommand(subcommand.subcommand)
            break
          else
            break
          end
        end
      end

      def parse_option(subcommand)
        # Split into name and argument
        case @argv.first
          when /^(--.+?)(?:=(.*))?$/
            name, arg, short = $1, $2, false
          when /^(-.)(.+)?$/
            name, arg, short = $1, $2, true
        end
        @argv.shift

        option = subcommand.grammar.options[name] or raise Error, "Unknown option '#{name}'"
        !@seen_options.key?(option.key) || option.repeated? or raise Error, "Duplicate option '#{name}'"
        @seen_options[option.key] = true

        # Parse (optional) argument
        if option.argument?
          if arg.nil? && !option.optional?
            if !@argv.empty?
              arg = @argv.shift
            else
              raise Error, "Missing argument for option '#{name}'"
            end
          end
          arg &&= parse_arg(option, name, arg)
        elsif arg && short
          @argv.unshift("-#{arg}")
          arg = nil
        elsif !arg.nil?
          raise Error, "No argument allowed for option '#{name}'"
        end

        subcommand.options << Ast::Option.new(option, name, arg)
      end

      def parse_arg(option, name, arg)
        if option.string?
          arg
        elsif arg == ""
          nil
        elsif option.integer?
          arg =~ /^-?\d+$/ or raise Error, "Illegal integer in '#{name}' argument: '#{arg}'"
          arg.to_i
        else # option.float?
          # https://stackoverflow.com/a/21891705/2130986
          arg =~ /^[+-]?(?:0|[1-9]\d*)(?:\.(?:\d*[1-9]|0))?$/ or
              raise Error, "Illegal float in '#{name}' argument: '#{arg}'"
          arg.to_f
        end
      end
    end
  end
end
