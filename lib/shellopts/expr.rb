
module ShellOpts
  module Expr
    # Command represents a program or a subcommand. It is derived from
    # BasicObject to have only a minimum of built in member methods
    #
    # TODO
    # In addition to the methods defined below the following methods are
    # created dynamically for each declared option with an identifier (options
    # without an identifier can still be accessed using #[] or the #options
    # array):
    #
    #   def <identifier>(default = nil) self["<identifier>"] || default end
    #   def <identifier>=(value) self["<identifier>"] = value end
    #   def <identifier>?() self.key?("<identifier>") end
    #
    # And for each declared command:
    #
    #   # Return the sub-command object or nil if not present
    #   def <identifier>!() command == "identifier" ? @__command__ : nil end
    #
    class Command < BasicObject
      RESERVED_OPTION_NAMES = %w(
          initialize instance_eval instance_exec method_missing
          singleton_method_added singleton_method_removed
          singleton_method_undefined)

      def self.new(grammar)
        object = super()
        object.__send__(:__initialize__, grammar)
        object
      end

      # Return the associated option argument or nil if not present. The name can
      # be any of the names associated with an option as Symbol or String objects
      #
      # The returned value is the argument given by the user (optionally
      # converted to Integer or Float) or nil if the option doesn't take
      # arguments. If the option takes an argument and it is repeatable the value
      # is an array of the arguments. Repeatable options without arguments have
      # the number of occurences as the value
      #
      def [](name) @__options__[__identifier__(name)] end

      # Assign a value to an existing option. This can be used to implement
      # default values. #[]= doesn't currently check the type of the given value
      # so take care. Note that the corresponding option(s) in #user_options is not
      # updated
      def []=(name, value) @__options__[__identifier__(name)] = value end

      # Return true if the given option was used. It is an error if name is not
      # declared as an option
      def key?(name) @__options__.key?(__identifier__(name)) end

      # Hash from identifier to value. Can be Integer, Float, or String
      # depending on the option's type. Repeated options options without
      # arguments have the number of occurences as the value, with arguments
      # the value is an array of the given values
      #
      # Note: Can be overriden by an option, in that case use #__options__
      # instead
      def options() @__options__ end

      # List of Expr::UserOption objects for the command in the same order as
      # given by the user but note that options are reordered to come after
      # their associated subcommand if float is true. Repeated options are not
      # collapsed
      #
      # Note: Can be overridden by an option, in that case use
      # #__user_options__ or ::options instead. #options is usually not
      # necessary when processing the command line
      #
      # TODO: Rename option_list
      def user_options() __user_options__ end

      # The sub-command identifier (a Symbol incl. the exclamation mark) or nil
      # if not present. Use #command!, or the dynamically generated
      # '#<identifier>!' method to get the actual command object
      #
      # Can be overridden by an option, in that case use #__command__()
      # or ::command instead. #command is often used in case statement to
      # branch out to code that handles the given command:
      #
      #   prog, args = ShellOpts.parse("do_this! do_that!", ARGV)
      #   case prog.command
      #     when :do_this!; prog.do_this.handle
      #     when :do_that!; ...
      #   end
      #
      def command() __command__ end

      # The actual sub-command object or nil if not present
      #
      # Note: Can be overridden if a command named "command" is defined, in
      # that case use `Command.command(object)` to get the sub-command
      #
      def command!() __command__! end

      # Accessor methods that won't conflict with option names because options
      # can't start with an underscore
      attr_accessor :__supercommand__ # Initialized by add_command
      def __uid__() @__grammar__.uid end
      def __ident__() @__grammar__.ident end
      def __name__() @__grammar__.name end
      attr_reader :__grammar__
      attr_reader :__options__
      attr_reader :__user_options__
      def __command__() @__command__&.__ident__ end
      def __command__!() @__command__ end

      # Class-level accessor methods. Note: Also defined in ShellOpts::ShellOpts
      def self.supercommand(command) command.__supercommand__ end
      def self.uid(command) command.__uid__ end
      def self.ident(command) command.__ident__ end
      def self.name(command) command.__name__ end
      def self.grammar(command) command.__grammar__ end
      def self.options(command) command.__options__ end
      def self.user_options(command) command.__user_options__ end
      def self.command(command) command.__commmand__ end
      def self.command!(command) command.__command__! end

    private
      def __initialize__(grammar)
        @__grammar__ = grammar
        @__options__ = {}
        @__user_options__ = [] 
        @__options__ = {}
        @__command__ = nil

        __define_option_methods__
      end

      def __define_option_methods__
        @__grammar__.options.each { |opt|
          if opt.argument? || opt.repeatable?
            if opt.optional?
              self.instance_eval %(
                def #{opt.ident}(default = nil)
                  if @__options__.key?(:#{opt.ident}) 
                    @__options__[:#{opt.ident}] || default
                  else
                    nil
                  end
                end
              )
            elsif !opt.argument?
              self.instance_eval %(
                def #{opt.ident}(default = nil) 
                  if @__options__.key?(:#{opt.ident})
                    value = @__options__[:#{opt.ident}] 
                    value == 0 ? default : value
                  else
                    nil
                  end
                end
              )
            else
              self.instance_eval("def #{opt.ident}() @__options__[:#{opt.ident}] end")
            end
            self.instance_eval("def #{opt.ident}=(value) @__options__[:#{opt.ident}] = value end")
            @__options__[opt.ident] = 0 if !opt.argument?
          end
          self.instance_eval("def #{opt.ident}?() @__options__.key?(:#{opt.ident}) end")
        }

        @__grammar__.commands.each { |cmd|
          self.instance_eval %(
            def #{cmd.ident}() 
              :#{cmd.ident} == __command__ ? __command__! : nil
            end
          )
        }
      end

      # Canonical name (identifier, actually)
      def __identifier__(name)
        @__grammar__[name]&.ident or 
            raise InterpreterError, "Unknown option name: #{name.inspect}"
      end

      def __add_option__(option)
        ident = option.grammar.ident
        @__user_options__ << option
        if option.repeatable?
          if option.argument?
            (@__options__[ident] ||= []) << option.argument
          else
            @__options__[ident] ||= 0
            @__options__[ident] += 1
          end
        else
          @__options__[ident] = option.argument
        end
      end

      def __add_command__(command)
        command.__supercommand__ = self
        @__command__ = command
      end

      def self.add_option(command, option) command.__send__(:__add_option__, option) end
      def self.add_command(command, cmd) command.__send__(:__add_command__, cmd) end
    end

    class Program < Command
    end

    # This models an option as given by the user on the command line. Compiled
    # options (and possibly aggregated) options are stored in the
    # Command#__options__ array
    class UserOption
      # Associated Grammar::Option object
      attr_reader :grammar

      # The actual name used on the command line (String)
      attr_reader :name 

      # Argument value or nil if not present. The value is a String, Integer,
      # or Float depending the on the type of the option
      attr_accessor :argument

      forward_to :grammar, 
          :uid, :ident,
          :repeatable?, :argument?, :integer?, :float?,
          :file?, :enum?, :string?, :optional?,
          :argument_name, :argument_type, :argument_enum

      def initialize(grammar, name, argument)
        @grammar, @name, @argument = grammar, name, argument
      end
    end
  end
end
