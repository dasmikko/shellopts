require "ext/array.rb"

require 'shellopts/grammar/node.rb'
require 'shellopts/grammar/option.rb'
require 'shellopts/grammar/command.rb'
require 'shellopts/grammar/program.rb'

module ShellOpts
  module Grammar
    # Compiles an option definition string and returns a Grammar::Program
    # object. program_name is the name of the program and source is the 
    # option definition string
    def self.compile(program_name, source)
      program_name.is_a?(String) or raise Compiler::Error, "Expected String argument, got #{program_name.class}"
      source.is_a?(String) or raise Compiler::Error, "Expected String argument, got #{source.class}"
      Compiler.new(program_name, source).call
    end

    # Service object for compiling an option definition string. Returns a 
    # Grammar::Program object
    #
    # Compiler implements a recursive descend algorithm to compile the option
    # string. The algorithm uses state variables and is embedded in a
    # Grammar::Compiler service object 
    class Compiler
      class Error < RuntimeError; end

      # Initialize a Compiler object. source is the option definition string
      def initialize(program_name, source)
        @program_name, @tokens = program_name, source.split(/\s+/).reject(&:empty?)

        # @commands_by_path is an hash from command-path to Command or Program
        # object. The top level Program object has nil as its path.
        # @commands_by_path is used to check for uniqueness of commands and to
        # link sub-commands to their parents
        @commands_by_path = {}
      end

      def call
        compile_program
      end

    private
      using XArray # For Array#find_dup

      # Returns the current token
      def curr_token() @tokens.first end

      # Returns the current token and advance to the next token
      def next_token() @tokens.shift end

      def error(msg) # Just a shorthand. Unrelated to ShellOpts.error
        raise Compiler::Error.new(msg)
      end

      def compile_program
        program = @commands_by_path[nil] = Grammar::Program.new(@program_name, compile_options)
        while curr_token && curr_token != "--"
          compile_command
        end
        program.args.concat(@tokens[1..-1]) if curr_token
        program
      end

      def compile_command
        path = curr_token[0..-2]
        ident_list = compile_ident_list(path, ".")
        parent_path = ident_list.size > 1 ? ident_list[0..-2].join(".") : nil
        name = ident_list[-1]

        parent = @commands_by_path[parent_path] or
            error "No such command: #{parent_path.inspect}"
        !@commands_by_path.key?(path) or error "Duplicate command: #{path.inspect}"
        next_token
        @commands_by_path[path] = Grammar::Command.new(parent, name, compile_options)
      end

      def compile_options
        option_list = []
        while curr_token && curr_token != "--" && !curr_token.end_with?("!")
          option_list << compile_option
        end
        dup = option_list.map(&:names).flatten.find_dup and 
            error "Duplicate option name: #{dup.inspect}"
        option_list
      end

      def compile_option
        # Match string and build flags
        flags = []
        curr_token =~ /^(\+)?(.+?)(?:(=)(\$|\#)?(.*?)(\?)?)?$/
        flags << :repeated if $1 == "+"
        names = $2
        flags << :argument if $3 == "="
        flags << :integer if $4 == "#"
        flags << :float if $4 == "$"
        label = $5 == "" ? nil : $5
        flags << :optional if $6 == "?"

        # Build names
        short_names = []
        long_names = []
        ident_list = compile_ident_list(names, ",")
        (dup = ident_list.find_dup).nil? or 
            error "Duplicate identifier #{dup.inspect} in #{curr_token.inspect}"
        ident_list.each { |ident|
          if ident.size == 1
            short_names << "-#{ident}"
          else
            long_names << "--#{ident}"
          end
        }

        next_token
        Grammar::Option.new(short_names, long_names, flags, label)
      end

      # Compile list of option names or a command path
      def compile_ident_list(ident_list_str, sep)
        ident_list_str.split(sep, -1).map { |str| 
          !str.empty? or error "Empty identifier in #{curr_token.inspect}"
          !str.start_with?("-") or error "Identifier can't start with '-' in #{curr_token.inspect}"
          str !~ /([^\w\d#{sep}-])/ or 
              error "Illegal character #{$1.inspect} in #{curr_token.inspect}"
          str
        }
      end
    end
  end
end
