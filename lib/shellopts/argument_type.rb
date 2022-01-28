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
      attr_reader :kind # :file, :dir, :path, :efile, :edir, :epath, :nfile, :ndir, :npath

      def initialize(kind)
        constrain kind, :file, :dir, :path, :efile, :edir, :epath, :nfile, :ndir, :npath
        @kind = kind 
      end

      def match?(name, value)
        case kind
          when :file; match_path(name, value, kind, :file?, :default)
          when :dir; match_path(name, value, kind, :directory?, :default)
          when :path; match_path(name, value, kind, :exist?, :default)

          when :efile; match_path(name, value, kind, :file?, :exist)
          when :edir; match_path(name, value, kind, :directory?, :exist)
          when :epath; match_path(name, value, kind, :exist?, :exist)

          when :nfile; match_path(name, value, kind, :file?, :new)
          when :ndir; match_path(name, value, kind, :directory?, :new)
          when :npath; match_path(name, value, kind, :exist?, :new)
        else
          raise InternalError, "Illegal kind: #{kind.inspect}"
        end
      end

    protected
      def match_path(name, value, kind, method, mode)
        subject = 
            case kind
              when :file, :efile, :nfile; "regular file"
              when :dir, :edir, :ndir; "directory"
              when :path, :epath, :npath; "path"
            else
              raise ArgumentError
            end

        if File.send(method, value) # exists?
          if mode == :new
            set_message "#{subject.capitalize} already exists"
          elsif kind == :path || kind == :epath
            if File.file?(value) || File.directory?(value)
              true
            else
              set_message "Expected regular file or directory as #{name} argument: #{value}"
            end
          else
            true
          end
        elsif File.exist?(value) # exists but not the right type
          if mode == :new
            set_message "#{subject.capitalize} already exists"
          else
            set_message "Expected #{subject} as #{name} argument: #{value}"
          end
        else # does not exist
          if [:default, :new].include? mode
            if File.exist?(File.dirname(value))
              true
            else
              set_message "Illegal path in #{name}: #{value}"
            end
          else
            set_message "Error in #{name} argument: Can't find #{value}"
          end
        end
      end
    end

    class EnumArgument < ArgumentType
      attr_reader :values
      def initialize(values) @values = values.dup end
      def match?(value) values.include?(value) or set_message "Illegal value: '#{value}'" end
    end
  end
end

