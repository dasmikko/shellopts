
# TODO: Create a BasicShellOptsObject with is_a? and operators defined
#
module ShellOpts
  # Command represents a program or a subcommand. It is derived from
  # BasicObject to have only a minimum of inherited member methods.
  # Additional methods defined in Command use the  '__<identifier>__' naming
  # convention that doesn't collide with option or subcommand names but
  # they're rarely used in application code
  #
  # The names of the inherited methods can't be used as options or
  # command namess. They are: instance_eval, instance_exec method_missing,
  # singleton_method_added, singleton_method_removed, and
  # singleton_method_undefined
  #
  # Command also defines #subcommand and #subcommand! but they can be
  # overshadowed by an option or command declaration. Their values can
  # still be accessed using the dashed name, though
  #
  # Options and subcommands can be accessed using #[]
  #
  # The following methods are created dynamically for each declared option
  # with an attribute name
  #
  #   def <identifier>(default = nil) self["<identifier>"] || default end
  #   def <identifier>=(value) self["<identifier>"] = value end
  #   def <identifier>?() self.key?("<identifier>") end
  #
  # Options without an an attribute can still be accessed using #[] or trough
  # #__options__ or #__options_list__):
  #
  # Each subcommand has a single method:
  #
  #   # Return the subcommand object or nil if not present
  #   def <identifier>!() subcommand == :<identifier> ? @__subcommand__ : nil end
  #
  # The general #subcommand method can be used to find out which subcommand is
  # used
  #
  class Command < BasicObject
    define_method(:is_a?, ::Kernel.method(:is_a?))

    # These names can't be used as option or command names
    RESERVED_OPTION_NAMES = %w(
        is_a
        instance_eval instance_exec method_missing singleton_method_added
        singleton_method_removed singleton_method_undefined)

    # These methods can be overridden by an option (the value is not used -
    # this is just for informational purposes)
    OVERRIDEABLE_METHODS = %w(
        subcommand
    )

    # Redefine ::new to call #__initialize__
    def self.new(grammar)
      object = super()
      object.__send__(:__initialize__, grammar)
      object
    end

    # Return command object or option argument or nil if not present
    #
    # The key is the name or identifier of the object or any any option
    # alias. Eg.  :f, '-f', :file, or '--file' are all usable as option keys
    # and :cmd!  or 'cmd' as command keys
    #
    # For options, the returned value is the argument given by the user
    # optionally converted to Integer or Float or nil if the option doesn't
    # take arguments. If the option takes an argument and it is repeatable
    # the value is an array of the arguments. Repeatable options without
    # arguments have the number of occurences as the value
    #
    def [](key)
      case object = __grammar__[key]
        when ::ShellOpts::Grammar::Command
          object.ident == __subcommand__!.__ident__ ? __subcommand__! : nil
        when ::ShellOpts::Grammar::Option
          __options__[object.ident]
        else
          nil
      end
    end

    # Assign a value to an existing option. This can be used to implement
    # default values. #[]= doesn't currently check the type of the given
    # value so take care. Note that the corresponding option(s) in
    # #__option_list__ is not updated
    def []=(key, value)
      case object = __grammar__[key]
        when ::ShellOpts::Grammar::Command
          ::Kernel.raise ArgumentError, "#{key.inspect} is not an option"
        when ::ShellOpts::Grammar::Option
          object.argument? || object.repeatable? or
              ::Kernel.raise ArgumentError, "#{key.inspect} is not assignable"
          __options__[object.ident] = value
        else
          ::Kernel.raise ArgumentError, "Unknown option or command: #{key.inspect}"
      end
    end

    # Return true if the given command or option is present
    def key?(key)
      case object = __grammar__[key]
        when ::ShellOpts::Grammar::Command
          object.ident == __subcommand__!.ident ? __subcommand__! : nil
        when ::ShellOpts::Grammar::Option
          __options__.key?(object.ident)
        else
          nil
      end
    end
      
    # Subcommand identifier or nil if not present. #subcommand is often used in
    # case statement to branch out to code that handles the given subcommand:
    #
    #   prog, args = ShellOpts.parse("do_this! do_that!", ARGV)
    #   case prog.subcommand
    #     when :do_this!; prog.do_this.operation # or prog[:subcommand!] or prog.subcommand!
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
    # Note: Can be overridden by a subcommand declaration (but not an
    # option), in that case use #__subcommand__! or
    # ShellOpts.subcommand!(object) instead
    #
    def subcommand!() __subcommand__! end

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

    # List of Option objects for the subcommand in the same order as
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
        next if opt.attr.nil?
        if opt.argument? || opt.repeatable?
          if opt.optional?
            self.instance_eval %(
              def #{opt.attr}(default = nil)
                if @__options__.key?(:#{opt.attr}) 
                  @__options__[:#{opt.attr}] || default
                else
                  nil
                end
              end
            )
          elsif !opt.argument?
            self.instance_eval %(
              def #{opt.attr}(default = nil) 
                if @__options__.key?(:#{opt.attr})
                  value = @__options__[:#{opt.attr}] 
                  value == 0 ? default : value
                else
                  nil
                end
              end
            )
          else
            self.instance_eval("def #{opt.attr}() @__options__[:#{opt.attr}] end")
          end
          self.instance_eval("def #{opt.attr}=(value) @__options__[:#{opt.attr}] = value end")
          @__options__[opt.attr] = 0 if !opt.argument?
        end
        self.instance_eval("def #{opt.attr}?() @__options__.key?(:#{opt.attr}) end")
      }

      @__grammar__.commands.each { |cmd|
        next if cmd.attr.nil?
        self.instance_eval %(
          def #{cmd.attr}() 
            :#{cmd.attr} == __subcommand__ ? __subcommand__! : nil
          end
        )
      }
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

  # The top-level command
  class Program < Command
  end

  # Option models an option as given by the user on the subcommand line.
  # Compiled options (and possibly aggregated) options are stored in the
  # Command#__options__ array
  class Option
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
