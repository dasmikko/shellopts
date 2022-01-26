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
              when ArgumentType
                puts "#{attr}: #{value}"
            else
#             value = value.inspect if value.nil? || !value.respond_to?(:to_s)
              puts "#{attr}: #{value.inspect}"
            end
          }
        }
      end

    protected
      def classname() self.class.to_s.sub(/.*::/, "") end
    end

    class Option < IdrNode
      def dump_idr
        puts "#{name}: #{classname}"
        dump_attrs(
            :uid, :path, :attr, :ident, :name, :idents, :names, :brief,
            :repeatable?, 
            :argument?, argument? && :argument_name, argument? && :argument_type, 
            :integer?, :float?, :file?, 
            :enum?, enum? && :argument_enum, :string?, 
            :optional?)
      end
    end

    class Command < IdrNode
      def dump_idr
        puts "#{name}: #{classname}"
        dump_attrs :uid, :path, :ident, :name, :options, :commands, :specs, :usages, :brief
      end
    end

    class Spec < Node
      def dump_idr
        super
        dump_attrs :arguments
      end
    end

    class Argument < Node
      def dump_idr
        puts "<type>"
      end
    end
  end
end
