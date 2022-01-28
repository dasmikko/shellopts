module ShellOpts
  module Ast
    class Command < BasicObject
      def dump
        klass = __is_program__ ? "Program" : "Command"
        ::Kernel.puts "#{@grammar.ident.inspect} (#{klass})"
        ::Kernel.indent {
          if !options.empty?
            options.map(&:dump)
          end
          if subcommand
            subcommand!.dump
          end
        }
      end
    end

    class Option
      def dump
        puts "#{grammar.ident.inspect} (Option)"
        indent {
          puts "name: #{name.inspect}"
          puts "argument: #{argument.inspect}"
        }
      end
    end
  end
end
