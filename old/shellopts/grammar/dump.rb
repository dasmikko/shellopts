module ShellOpts
  module Grammar
    class Command
      def dump
        print (path ? "#{path}!" : 'nil')
        print " (virtual)" if virtual?
        print " [PROGRAM]" if program?
        puts
        indent {
          puts "name: #{name.inspect}"
          puts "ident: #{ident.inspect}"
          puts "path: #{path.inspect}"
          puts "parent_path: #{parent_path.inspect}"
          if !text.empty?
            puts "text"
            indent { text.each { |txt| puts txt } }
          end
          if !opts.empty?
            puts "opts"
            indent { opts.each(&:dump) }
          end
          if !cmds.empty?
            puts "cmds (#{cmds.size})"
            indent { cmds.each(&:dump) }
          end
          if !args.empty?
            puts "args"
            indent { args.each { |arg| puts arg } }
          end
        }
      end
    end

    class Option
      def dump
        puts name
        indent {
          if !text.empty?
            puts "text"
            indent { text.each { |txt| puts txt } }
          end
          puts "ident: #{ident.inspect}"
          puts "names: #{names.join(', ')}"
          puts "repeatable: #{repeatable?}"
          puts "argument: #{argument?}"
          if argument?
            puts "argument_name: #{argument_name}" if argument_name
            puts "integer: #{integer?}"
            puts "float: #{float?}"
            puts "optional: #{optional?}"
          end
        }
      end
    end
  end
end
