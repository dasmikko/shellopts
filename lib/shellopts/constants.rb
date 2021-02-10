
module ShellOpts
  # FIXME: An option group is -abcd, an option list is a,b,c,d
  module Constants
    # Short and long option names
    SHORT_OPTION_NAME_SUB_RE = /[a-zA-Z0-9]/
    LONG_OPTION_NAME_SUB_RE = /[a-z](?:[\w-]*\w)/
    OPTION_NAME_SUB_RE = /#{SHORT_OPTION_NAME_SUB_RE}|#{LONG_OPTION_NAME_SUB_RE}/

    # Initial option in a group
    INITIAL_SHORT_OPTION_SUB_RE = /[-+]#{SHORT_OPTION_NAME_SUB_RE}/
    INITIAL_LONG_OPTION_SUB_RE = /(?:--|\+\+)#{LONG_OPTION_NAME_SUB_RE}/
    INITIAL_OPTION_SUB_RE = /#{INITIAL_SHORT_OPTION_SUB_RE}|#{INITIAL_LONG_OPTION_SUB_RE}/

    # A list of short and long options
    OPTION_GROUP_SUB_RE = /#{INITIAL_OPTION_SUB_RE}(?:,#{OPTION_NAME_SUB_RE})*/

    # Option argument
    OPTION_ARG_SUB_RE = /[A-Z](?:[A-Z0-9_-]*[A-Z0-9])?/
    
    # Matches option flags and argument. It defines the following captures
    #
    #   $1 - Argument flag ('=')
    #   $2 - Type flag ('#' or '$')
    #   $3 - Argument name
    #   $4 - Optional flag ('?')
    #
    OPTION_FLAGS_SUB_RE = /(=)(#|\$)?(#{OPTION_ARG_SUB_RE})?(\?)?/

    # Matches a declaration of an option. The RE defines the following captures:
    #
    #   $1 - Option group
    #   $2 - Argument flag ('=')
    #   $3 - Type flag ('#' or '$')
    #   $4 - Argument name
    #   $5 - Optional flag ('?')
    #
    OPTION_SUB_RE = /(#{OPTION_GROUP_SUB_RE})#{OPTION_FLAGS_SUB_RE}?/
    
    # Command and command paths
    COMMAND_IDENT_SUB_RE = /[a-z](?:[a-z0-9_-]*[a-z0-9])?/
    COMMAND_SUB_RE = /#{COMMAND_IDENT_SUB_RE}!/
    COMMAND_PATH_SUB_RE = /#{COMMAND_IDENT_SUB_RE}(?:\.#{COMMAND_IDENT_SUB_RE})*!/

    # Command argument
    ARGUMENT_SUB_RE = /[A-Z][A-Z0-9_-]*[A-Z0-9](?:\.\.\.)?/
    ARGUMENT_EXPR_SUB_RE = /\[?#{ARGUMENT_SUB_RE}(?:#{ARGUMENT_SUB_RE}|[\[\]\|\s])*/

    # Matches a line starting with a command or an option
    SCAN_RE = /^(?:#{COMMAND_PATH_SUB_RE}|#{OPTION_SUB_RE})(?:\s+.*)?$/


    # Create anchored REs for all SUB_REs
    self.constants.each { |c|
      next if c.to_s !~ /_SUB_RE$/
      sub_re = self.const_get(c)
      next if !sub_re.is_a?(Regexp)
      re = /^#{sub_re}$/
      name = c.to_s.sub(/_SUB_RE$/, "_RE")
      self.const_set(name, re)
    }

    # Method names reserved by the BasicObject class
    BASIC_OBJECT_RESERVED_WORDS = %w(
      ! != == __id__ __send__ equal? instance_eval instance_exec method_missing
      singleton_method_added singleton_method_removed singleton_method_undefined)

    # Method names reserved by the Ast::Command class
    AST_COMMAND_RESERVED_WORDS = %w(
      initialize options subcommand __is_program__ __get_grammar__
      __add_option__ __add_command__)

    # Reserved option names
    OPTION_RESERVED_WORDS = 
        (BASIC_OBJECT_RESERVED_WORDS + AST_COMMAND_RESERVED_WORDS).grep(OPTION_NAME_RE)

    # Reserved command names
    COMMAND_RESERVED_WORDS = %w(subcommand)
  end

  include Constants
end






