module ShellOpts
  module Grammar
    class ArgumentType
      def convert(value) value end
      def match?(value) true end
    end

    class IntegerArgument < ArgumentType
      def match?(value) value.is_a?(Integer) end
      def convert(value) value.to_i end
    end

    class FloatArgument < ArgumentType
      def match?(value) value.is_a?(Number) end
      def convert(value) value.to_f end
    end

    class FileArgument < ArgumentType
      attr_reader :kind # :file, :dir, :node, :filepath, :dirpath, :path, :new
      def initialize(kind) 
        @kind = kind 
      end
      def match?(value)
        case kind
          when :file; File.file?(value)
          when :dir; File.directory?(value)
          when :node; File.exist?(value)
          when :filepath; File.file?(value) || File.exist?(File.dirname(value))
          when :dirpath; File.directory?(value) || File.exist?(File.dirname(value))
          when :path; File.exist?(value) || File.exist?(File.dirname(value))
        else
          raise InternalError, "Illegal kind: #{kind.inspect}"
        end
      end
    end

    class EnumArgument < ArgumentType
      attr_reader :values
      def initialize(values) @values = values.dup end
      def match?(value) values.include?(value) end
    end
  end
end

