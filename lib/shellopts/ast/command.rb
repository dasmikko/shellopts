module ShellOpts
  module Ast
    # Note that Command is derived from BasicObject to minimize the number of
    # reserved names
    class Command < BasicObject
      def initialize(grammar)
        @grammar = grammar
        @options_list = []
        @options_hash = {}
        @subcommand = nil
        @subcommands_hash = {} # have at most one element

        @grammar.opts.each { |opt|
          if opt.argument?
            self.instance_eval("def #{opt.ident}() @options_hash[:#{opt.ident}] end")
          end
          self.instance_eval("def #{opt.ident}?() @options_hash.key?(:#{opt.ident}) end")
        }

        @grammar.cmds.each { |cmd|
          self.instance_eval("def #{cmd.ident}!() @subcommands_hash[:#{cmd.ident}] end")
        }
      end

      # Return true if the option was used. Defined in #initialize for each option
      # def <option>?() end
      
      # Return the value of the option. Note that repeated options have their
      # values aggregated into an array. Defined in #initialize for each option
      # def <option>() end

      # List of Ast::Option objects in the same order as on the command line
      def options() @options_list end
      
      # Hash from option identifier to option value. Note that repeated options
      # have their values aggregated into an array
      def [](ident) @options_hash[ident].argument end

      # Return the sub-command Command object or nil if not present. Defined in
      # #initialize for each sub-command
      # def <command>!() end

      # The sub-command identifier or nil if not present. TODO: Rename #command
      def subcommand() @subcommand && Command.grammar(@subcommand).ident end

      # The sub-command Command object or nil if not present
      def subcommand!() @subcommand end

      # Class-level accessor methods
      def self.program?(command) command.__send__(:__is_program__) end
      def self.grammar(command) command.__send__(:__get_grammar__) end

      # Class-level mutating methods
      def self.add_option(command, option) command.__send__(:__add_option__, option) end
      def self.add_command(command, subcommand) command.__send__(:__add_command__, subcommand) end

    private
      # True if this is a Program object
      def __is_program__() false end

      # Get grammar
      def __get_grammar__()
        @grammar
      end

      # Add an option. Only used from the parser
      def __add_option__(option)
        @options_list << option
        if option.grammar.repeatable?
          (@options_hash[option.grammar.ident] ||= []) << option.argument
        else
          @options_hash[option.grammar.ident] = option.argument
        end
      end

      # Set sub-command. Only used from the parser
      def __add_command__(command)
        ident = Command.grammar(command).ident
        @subcommand = command
        @subcommands_hash[ident] = command
      end
    end

    class Program < Command
      def __is_program__() true end
    end
  end
end

# # TODO: Create class-level methods for access
# private
#   # Return class of object. #class is not defined for BasicObjects so this
#   # method provides an alternative way of getting the class
#   def self.class_of(object) 
#     # https://stackoverflow.com/a/18621313/2130986
#     ::Kernel.instance_method(:class).bind(object).call 
#   end
#
#   # Class method implementation of ObjectStruct#instance_variable_set that is
#   # not defined in a BasicObject
#   def self.set_variable(this, var, value)
#     # https://stackoverflow.com/a/18621313/2130986
#     ::Kernel.instance_method(:instance_variable_set).bind(this).call(var, value)
#   end
#
#   # Class method implementation of ObjectStruct#instance_variable_get that is
#   # not defined in a BasicObject
#   def self.get_variable(this, var)
#     # https://stackoverflow.com/a/18621313/2130986
#     ::Kernel.instance_method(:instance_variable_get).bind(this).call(var)
#   end

