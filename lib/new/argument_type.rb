module ShellOpts
  module Grammar
    class ArgumentType
      # Name of type
      def name() self.class.to_s.sub(/.*::/, "").sub(/Argument/, "") end

      # Return truish if type match the value. <name> is used to construct an
      # error message (stored in #message) and is the name/alias the user
      # specified on the command line
      def match?(name, value) true end

      # Return error message if match? returned false
      attr_reader :message

      # Convert value to Ruby type
      def convert(value) value end

      # String representation. Equal to #name
      def to_s() name end

    protected
      # it is important that #set_message return false
      def set_message(msg)
        @message = msg
        false
      end
    end

    class StringType < ArgumentType
    end

    class IntegerArgument < ArgumentType
      def match?(name, value) 
        value =~ /^-?\d+$/ or 
            set_message "Illegal integer value in #{name}: #{value}" 
      end

      def convert(value) value.to_i end
    end

    class FloatArgument < ArgumentType
      def match?(name, value) 
        # https://stackoverflow.com/a/21891705/2130986
        value =~ /^[+-]?(?:0|[1-9]\d*)(?:\.(?:\d*[1-9]|0))?$/ or 
            set_message "Illegal decimal value in #{name}: #{value}"
      end

      def convert(value) value.to_f end
    end

    class FileArgument < ArgumentType
      attr_reader :kind # :file, :dir, :node, :filepath, :dirpath, :path, :new

      def initialize(kind) 
        @kind = kind 
      end

      def match?(name, value)
        puts "#{kind} matching against #{value.inspect}"
        case kind
          when :file; match_path(name, value, "regular file", :file?, false)
          when :dir; match_path(name, value, "directory", :file?, false)
          when :node; match_path(name, value, nil, :exist?, false)
          when :filepath; match_path(name, value, "regular file", :file?, true)
          when :dirpath; match_path(name, value, "directory", :directory?, true)
          when :path; match_path(name, value, nil, :exist?, true)
        else
          raise InternalError, "Illegal kind: #{kind.inspect}"
        end
      end

      def match_path(name, value, subject, method, use_path)
        if File.send(method, value)
          true
        elsif File.exist?(value)
          set_message "Expected #{subject} as #{name} argument: #{value}"
        elsif File.exist?(File.dirname(value))
          use_path or set_message "Error in #{name} argument: Can't find #{value}"
        else
          set_message "Illegal path in #{name}: #{value}"
        end
      end
    end

    class EnumArgument < ArgumentType
      attr_reader :values
      def initialize(values) @values = values.dup end
      def match?(name, value) 
        values.include?(value) or set_message "Illegal argument for #{name}: '#{value}'" end
    end
  end
end

