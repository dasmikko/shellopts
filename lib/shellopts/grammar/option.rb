module ShellOpts
  module Grammar
    # Models an Option
    #
    # Sets Node#key to the first long option name if present or else the first short option
    class Option < Node
      # List of short names (incl. '-')
      attr_reader :short_names

      # List of long names (incl. '--')
      attr_reader :long_names

      # Name of the key attribute (eg. if key is :all then key_name is '--all'
      attr_reader :key_name

      # List of flags (Symbol)
      def flags() @flags.keys end

      # Informal name of argument (eg. 'FILE'). nil if not present
      attr_reader :label

      # Initialize an option. Short and long names are arrays of the short/long
      # option names (incl. the '-'/'--' prefix). It is assumed that at least
      # one name is given. Flags is a list of symbolic flags. Allowed flags are
      # :repeated, :argument, :optional, :integer, and :float. Note that
      # there's no :string flag, it's status is inferred. label is the optional
      # informal name of the option argument (eg. 'FILE') or nil if not present
      def initialize(short_names, long_names, flags, label = nil)
        @key_name = long_names.first || short_names.first
        name = @key_name.sub(/^-+/, "")
        super(name.to_sym, name)
        @short_names, @long_names = short_names, long_names
        @flags = flags.map { |flag| [flag, true] }.to_h
        @label = label
      end

      # Array of option names with short names first and then the long names
      def names() @short_names + @long_names end

      # Array of names and the key
      def identifiers() names + [key] end

      # Return true if +ident+ is equal to any name or to key
      def match?(ident) names.include?(ident) || ident == key end

      # Flag query methods. Returns true if the flag is present and otherwise nil
      def repeated?() @flags[:repeated] || false end
      def argument?() @flags[:argument] || false end
      def optional?() argument? && @flags[:optional] || false end
      def string?() argument? && !integer? && !float? end
      def integer?() argument? && @flags[:integer] || false end
      def float?() argument? && @flags[:float] || false end

      # :nocov:
      def dump
        super {
          puts "short_names: #{short_names.inspect}"
          puts "long_names: #{long_names.inspect}"
          puts "flags: #{flags.inspect}"
          puts "label: #{label.inspect}"
        }
      end
      # :nocov:
    end
  end
end
