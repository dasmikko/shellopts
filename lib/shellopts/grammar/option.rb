module ShellOpts
  module Grammar
    class Option
      # Symbolic identifier. This is the name of the option with dashes ('-')
      # replaced with underscores ('_')
      attr_reader :ident

      # Name of option. This is the name of the first long option or the name
      # of the first short option if there is no long option name. It is used
      # to compute #ident
      attr_reader :name

      # Long name of option or nil if not present
      attr_reader :longname

      # Short name of option or nil if not present
      attr_reader :shortname

      # List of all names
      attr_reader :names

      # Name of argument or nil if not present
      attr_reader :argument_name

      # Comment
      attr_reader :text

      def repeatable?() @repeatable end
      def argument?() @argument end
      def integer?() @integer end
      def float?() @float end
      def string?() !@integer && !@float end
      def optional?() @optional end

      def initialize(names, repeatable: nil, argument: nil, integer: nil, float: nil, optional: nil)
        @names = names.dup
        @longname = @names.find { |name| name.length > 1 } 
        @shortname = @names.find { |name| name.length == 1 }
        @name = @longname || @shortname
        @ident = @name.gsub("-", "_").to_sym
        @repeatable = repeatable || false
        if argument
          @argument = true
          @argument_name = argument if argument.is_a?(String)
        else
          @argument = false
        end
        @integer = integer || false
        @float = float || false
        @optional = optional || false
        @text = []
      end
    end
  end
end
