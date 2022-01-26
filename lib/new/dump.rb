module ShellOpts
  module Grammar
    class Node
      def dump_ast
        puts "#{classname} @ #{token.pos} #{token.source}"
        indent { children.each(&:dump_ast) }
      end

      def dump_idr
        puts "#{classname}"
      end

      def dump_attrs(*attrs)
        indent {
          Array(attrs).flatten.select { |attr| attr.is_a?(Symbol) }.each { |attr|
            value = self.send(attr)
            case value
              when Node
                puts "#{attr}:"
                indent { node.dump_idr }
              when Array
                case value.first
                  when nil
                    puts "#{attr}: []"
                  when Node
                    puts "#{attr}:"
                    indent { value.each(&:dump_idr) }
                else
                  puts "#{attr}: #{value.inspect}"
                end
            else
              puts "#{attr}: #{value.inspect}"
            end
          }
        }
      end

    protected
      def classname() self.class.to_s.sub(/.*::/, "") end
    end

    class Option < Node
      def dump_idr
        puts "#{name}: #{classname}"
        dump_attrs(
            :ident, :name, :short_names, :long_names, :argument_name, :brief,
            :repeatable?, :argument?, :integer?, :float?, :file?, :enum?, enum? && :enum, :string?, 
            :optional?)
      end
    end

    class Command < Node
      def dump_idr
        puts "#{name}: #{classname}"
        dump_attrs :ident, :name, :path, :options, :commands, :specs, :usages, :brief
      end
    end
  end
end
