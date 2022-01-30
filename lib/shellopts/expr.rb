
module ShellOpts
  module Expr
    # Command represents a program or a (sub-)command. It is derived from
    # BasicObject to have only a minimum of built-in member methods. Other
    # member methods are using the '__<identifier>__' naming convention that
    # doesn't collide with option or subcommand names or are accessible through
    # a class method class method is with the same name that takes the command
    # as argument and return the corresponding value:
    #
    #   def ShellOpts.<identifier>(command) command.__<identifier>__ end
    #
    # The names of built-in methods can't be used as options or commands. They
    # are initialize, instance_eval, instance_exec method_missing,
    # singleton_method_added, singleton_method_removed, and
    # singleton_method_undefined
    #
    # The methods #subcommand and #subcommand! are also defined in Command but
    # can be overshadowed by an option or a command declaration. Their values
    # can still be accessed using the dashed name, though
    #
    # The following methods are created dynamically for each declared option
    # with an identifier (options without an identifier can still be accessed
    # using #[] or the #options array):
    #
    #   def <identifier>(default = nil) self["<identifier>"] || default end
    #   def <identifier>=(value) self["<identifier>"] = value end
    #   def <identifier>?() self.key?("<identifier>") end
    #
    # And for each subcommand:
    #
    #   # Return the subcommand object or nil if not present
    #   def <identifier>!() subcommand == :<identifier> ? @__subcommand__ : nil end
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
      # so take care. Note that the corresponding option(s) in #option_list is not
      # updated
      def []=(name, value) @__options__[__identifier__(name)] = value end

      # Return true if the given option was used. It is an error if name is not
      # declared as an option
      def key?(name) @__options__.key?(__identifier__(name)) end

      # Subcommand identifier or nil if not present. #subcommand is often used in
      # case statement to branch out to code that handles the given subcommand:
      #
      #   prog, args = ShellOpts.parse("!do_this !do_that", ARGV)
      #   case prog.subcommand
      #     when :do_this!; prog.do_this.operation
      #     when :do_that!; prog.do_that.operation
      #   end
      #
      # Note: Can be overridden by option, in that case use #__subcommand__ or
      # ShellOpts.subcommand(object) instead
      def subcommand() __subcommand__ end

      # The subcommand object or nil if not present. Per-subcommand methods
      # (#<identifier>!) are often used instead of #subcommand! to get the
      # subcommand
      #
      # Note: Can be overridden by a subcommand (but not an option), in that case
      # use #__subcommand__! or ShellOpts.subcommand!(object) instead
      #
      def subcommand!() __subcommand__! end

      # "Hidden" methods
      #

      # Accessor methods that won't conflict with option names because options
      # can't start with an underscore

      # The parent command or nil. Initialized by #add_command
      attr_accessor :__supercommand__

      # UID of command/program
      def __uid__() @__grammar__.uid end

      # Identfier including the exclamation mark (Symbol)
      def __ident__() @__grammar__.ident end

      # Name of command/program without the exclamation mark (String)
      def __name__() @__grammar__.name end

      # Grammar object
      attr_reader :__grammar__

      # Hash from identifier to value. Can be Integer, Float, or String
      # depending on the option's type. Repeated options options without
      # arguments have the number of occurences as the value, with arguments
      # the value is an array of the given values
      attr_reader :__options__

      # List of Expr::UserOption objects for the subcommand in the same order as
      # given by the user but note that options are reordered to come after
      # their associated subcommand if float is true. Repeated options are not
      # collapsed
      attr_reader :__option_list__
      
      # The subcommand identifier (a Symbol incl. the exclamation mark) or nil
      # if not present. Use #subcommand!, or the dynamically generated
      # '#<identifier>!' method to get the actual subcommand object
      def __subcommand__() @__subcommand__&.__ident__ end

      # The actual subcommand object or nil if not present
      def __subcommand__!() @__subcommand__ end

      # Class-level accessor methods. Note: Also defined in ShellOpts::ShellOpts. FIXME What?
      def self.supercommand(subcommand) subcommand.__supercommand__ end
      def self.uid(subcommand) subcommand.__uid__ end
      def self.ident(subcommand) subcommand.__ident__ end
      def self.name(subcommand) subcommand.__name__ end
      def self.grammar(subcommand) subcommand.__grammar__ end
      def self.options(subcommand) subcommand.__options__ end
      def self.option_list(subcommand) subcommand.__option_list__ end
      def self.subcommand(subcommand) subcommand.__commmand__ end
      def self.subcommand!(subcommand) subcommand.__subcommand__! end

    private
      def __initialize__(grammar)
        @__grammar__ = grammar
        @__options__ = {}
        @__option_list__ = [] 
        @__options__ = {}
        @__subcommand__ = nil

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
              :#{cmd.ident} == __subcommand__ ? __subcommand__! : nil
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
        @__option_list__ << option
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

      def __add_command__(subcommand)
        subcommand.__supercommand__ = self
        @__subcommand__ = subcommand
      end

      def self.add_option(subcommand, option) subcommand.__send__(:__add_option__, option) end
      def self.add_command(subcommand, cmd) subcommand.__send__(:__add_command__, cmd) end
    end

    class Program < Command
    end

    # UserOption models an option as given by the user on the subcommand line.
    # Compiled options (and possibly aggregated) options are stored in the
    # Command#__options__ array
    class UserOption
      # Associated Grammar::Option object
      attr_reader :grammar

      # The actual name used on the shell command-line (String)
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
