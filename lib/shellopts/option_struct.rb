
require 'shellopts/shellopts.rb'
require 'shellopts/idr'

module ShellOpts
  class OptionStruct < BasicObject
    # +key=:name+ cause command methods to be named without the exclamation
    # mark. It doesn't change how options are named
    def self.new(idr, key = :key, aliases = {})
      ast = idr.instance_variable_get("@ast")
      grammar = ast.grammar
      instance = allocate

      # Generate general option accessor methods
      grammar.option_list.each { |option|
        key = alias_key(option.key, aliases)
        instance.instance_eval("def #{key}() @#{key} end")
        instance.instance_eval("def #{key}?() false end")
      }

      # Generate accessor method for present options
      idr.option_list.each { |option|
        key = alias_key(option.key, aliases)
        set_variable(instance, "@#{key}", idr[option.key])
        instance.instance_eval("def #{key}?() true end")
      }

      # Generate general #subcommand methods
      if !idr.subcommand
        instance.instance_eval("def subcommand() nil end")
        instance.instance_eval("def subcommand?() false end")
        instance.instance_eval("def subcommand!() nil end")
      end

      # Generate individual subcommand methods
      grammar.command_list.each { |command|
        key = alias_key(command.key, aliases)
        if command.key == idr.subcommand&.key
          struct = OptionStruct.new(idr.subcommand, aliases[idr.subcommand.key] || {})
          set_variable(instance, "@subcommand", struct)
          instance.instance_eval("def #{key}() @subcommand end")
          instance.instance_eval("def subcommand() :#{key} end")
          instance.instance_eval("def subcommand?() true end")
          instance.instance_eval("def subcommand!() @subcommand end")
        else
          instance.instance_eval("def #{key}() nil end")
        end
      }

      instance
    end

  private
    # Return class of object. #class is not defined for BasicObjects so this
    # method provides an alternative way of getting the class
    def self.class_of(object) 
      # https://stackoverflow.com/a/18621313/2130986
      ::Kernel.instance_method(:class).bind(object).call 
    end

    # Replace key with alias and check against the list of reserved words
    def self.alias_key(internal_key, aliases)
      key = aliases[internal_key] || internal_key
      !RESERVED_WORDS.include?(key.to_s) or
        raise ::ShellOpts::ConversionError, "Can't create struct: '#{key}' is a reserved word"
      key
    end

    # Shorthand helper method. Substitutes the undefined ObjectStruct#instance_variable_set
    def self.set_variable(this, var, value)
      # https://stackoverflow.com/a/18621313/2130986
      ::Kernel.instance_method(:instance_variable_set).bind(this).call(var, value)
    end

    def self.get_variable(this, var)
      # https://stackoverflow.com/a/18621313/2130986
      ::Kernel.instance_method(:instance_variable_get).bind(this).call(var)
    end

    BASIC_OBJECT_RESERVED_WORDS = %w(
         __id__ __send__ instance_eval instance_exec method_missing
         singleton_method_added singleton_method_removed
         singleton_method_undefined)
    OPTIONS_STRUCT_RESERVED_WORDS = %w(subcommand)
    RESERVED_WORDS = BASIC_OBJECT_RESERVED_WORDS + OPTIONS_STRUCT_RESERVED_WORDS
  end
end








__END__

module ShellOpts
  # Struct representation of options. Usually created by ShellOpts::to_struct
  #
  # OptionStruct objects give easy access to configuration option values but
  # meta data are more circuitously accessed through class methods with an
  # explicit instance argument
  #
  # Option values are accessed through a member methods named after the key of
  # the option. Repeated options have an Array value with one element (possibly
  # nil) for each use of the option. A query method with a '?' suffixed to the
  # name returns true or false depending on whether the option was used or not
  #
  #   option   - Value of option. Either an object or an Array if the option can
  #              be repeated
  #   option?  - True iff option was given
  #
  # Command methods return a nested OptionStruct object while the special
  # #command method returns the key of actual command (if any). Use
  # +strukt.send(strukt.command)+ to get the subcommand of a OptionStruct. It
  # is possible to rename #command method to avoid name collisions 
  #
  #   name!   - Command. An OptionStruct or nil if not given on the command line
  #   subcommand - Key of command. Can be renamed
  #
  # ---------------------------------
  #   name!   - Command. An OptionStruct or nil if not given on the command line
  #
  #   key!    - Key of command
  #   value!  - Value of command (a subcommand). Can be renamed
  #
  # Note: There is no command query method because option and command names
  # live in seperate namespaces and could cause colllisions. Check +name!+ for
  # nil to detect if a command was given
  #
  # Meta data are extracted through class methods to avoid polluting the object
  # namespace. OptionStruct use an OptionsHash object internally and
  # implements a subset of its meta methods by forwarding to it. The
  # OptionsHash object can be accessed through the #options_hash method
  #
  # Note that #command is defined as both an instance method and a class
  # method. Use the class method to make the code work with all OptionStruct
  # objects even if #command has been renamed
  #
  # +ShellOpts+ is derived from +BascicObject+ that reserves some words for
  # internal use (+__id__+, +__send__+, +instance_eval+, +instance_exec+,
  # +method_missing+, +singleton_method_added+, +singleton_method_removed+,
  # +singleton_method_undefined+). ShellOpts also define two reserved words of
  # its own (+__options_hash__+ and +__command__+). ShellOpts raise an
  # ShellOpts::ConversionError if an option collides with one of the
  # reserved words or with the special #command method
  #
  class OptionStruct < BasicObject
    # Create a new OptionStruct instance from an AST. The optional
    # +options_hash+ argument is used to create subcommands without creating a
    # new options_hash argument. It is not meant for end-users. The
    # +command_alias+ names the method holding the key for the subcommand (if
    # any)
    def self.new(ast, options_hash = OptionsHash.new(ast), command_alias: :command)
      instance = allocate
      set_variable(instance, "@__options_hash__", options_hash)

      # Check for reserved words and +command_alias+
      options_hash.keys.each { |key| 
        !RESERVED_WORDS.include?(key.to_s) or 
          raise ::ShellOpts::ConversionError, "Can't create struct: '#{key}' is a reserved word"
        key != command_alias or
          raise ::ShellOpts::ConversionError, "Can't create struct: '#{key}' is the command alias"
      }

      # Create accessor methods
      ast.grammar.option_list.each { |option|
        instance.instance_eval("def #{option.key}() @#{option.key} end")
        instance.instance_eval("def #{option.key}?() false end")
      }
      ast.grammar.command_list.each { |command|
        instance.instance_eval("def #{command.key}() nil end")
      }

      # Assign values
      options_hash.each { |key, value|
        if value.is_a?(OptionsHash)
          set_variable(instance, "@__command__", OptionStruct.new(value.ast, value))
          instance.instance_eval("def #{key}() @__command__ end")
        else
          set_variable(instance, "@#{key}", value)
          instance.instance_eval("def #{key}?() true end")
        end
      }

      # Command accessor method
      instance.instance_eval("def #{command_alias}() @__options_hash__.command end")  

      instance
    end

    # Return the OptionsHash object from the instance
    def self.options_hash(instance)
      get_variable(instance, "@__options_hash__")
    end

    # Return class of object. #class is not defined for BasicObjects so this
    # method provides an alternative way of getting the class a BasicObject
    def self.class_of(object) 
      # https://stackoverflow.com/a/18621313/2130986
      ::Kernel.instance_method(:class).bind(object).call 
    end

    # Return the number of options and commands
    def self.size(instance)
      options_hash(instance).size
    end

    # Return the option and command keys. The keys are in order of occurrence
    # on the command line. A subcommand will always be the last element
    def self.keys(instance)
      options_hash(instance).keys
    end

    # Return the actual option name used on the command line for +name+. Use
    # +index+ to select between repeated options. Return the name of the
    # program/subcommand if key is nil
    def self.name(struct, key = nil, index = nil)
      options_hash(struct).name(key, index)
    end

    # Return the AST node for the option key or the AST node for the
    # OptionStruct if key is nil. Use +index+ to select between repeated
    # options. Raise InternalError if key doesn't exists
    def self.node(struct, key = nil, index = nil)
      options_hash(struct).node(key, index)
    end

    # Return key of the command of the struct (possibly nil)
    def self.command(struct)
      options_hash(struct).command
    end

  private
    BASIC_OBJECT_RESERVED_WORDS = %w(
         __id__ __send__ instance_eval instance_exec method_missing
         singleton_method_added singleton_method_removed
         singleton_method_undefined)
    OPTIONS_STRUCT_RESERVED_WORDS = %w(__options_hash__ __command__)
    RESERVED_WORDS = BASIC_OBJECT_RESERVED_WORDS + OPTIONS_STRUCT_RESERVED_WORDS 

    # Shorthand helper method. Substitutes the undefined ObjectStruct#instance_variable_set
    def self.set_variable(this, var, value)
      # https://stackoverflow.com/a/18621313/2130986
      ::Kernel.instance_method(:instance_variable_set).bind(this).call(var, value)
    end

    # Shorthand helper method: Substitutes the undefined ObjectStruct#instance_variable_get
    def self.get_variable(this, var)
      # https://stackoverflow.com/a/18621313/2130986
      ::Kernel.instance_method(:instance_variable_get).bind(this).call(var)
    end
  end
end 

