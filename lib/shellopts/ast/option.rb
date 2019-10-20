module ShellOpts
  module Ast
    class Option < Node
      # Optional value. Can be a String, Integer, or Float
      attr_reader :value

      def initialize(grammar, name, value)
        super(grammar, name)
        @value = value
      end

      def values() value end

      # :nocov:
      def dump
        super { puts "values: #{values.inspect}" }
      end
      # :nocov:
    end
  end
end
