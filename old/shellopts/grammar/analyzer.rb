
module ShellOpts
  module Grammar
    class Analyzer
      def self.analyze(commands)
        @program = commands.shift
        @commands = commands
        build_options
        link_up
        @program
      end

    private
      def self.error(mesg, command)
        mesg += " in #{command.path}" if !command.program?
        raise CompileError, mesg
      end

      def self.program() @program end
      def self.commands() @commands end

      # Initialize Command#options
      def self.build_options
        ([program] + commands).each { |command|
          command.opts.each { |opt|
            opt.names.each { |name|
              !command.options.key?(name) or 
                  error "Duplicate option name '#{name}'", command
              command.options[name] = opt
            }

            !command.options.key?(opt.ident) or 
                error "Duplicate option identifier '#{opt.ident}'", command
            command.options[opt.ident] = opt
          }
        }
      end

      # Initialize Command#commands
      def self.link_up
        # Hash from path to command
        cmds = { "" => program }

        # Add placeholders for actual commands and virtual commands for empty parent commands
        commands.sort.each { |cmd|
          # Place holder for actual command
          cmds[cmd.path] = nil

          # Add parent virtual commands 
          curr = cmd
          while !cmds.key?(curr.parent_path)
            curr = cmds[curr.parent_path] = VirtualCommand.new(curr.parent_path)
          end
        }

        # Add actual commands
        commands.sort.each { |cmd|
          !cmds[cmd.path] or 
              error "Duplicate command name '#{cmd.name}'", cmds[cmd.parent_path]
          cmds[cmd.path] = cmd
        }

        # Link up
        cmds.values.each { |cmd|
          next if cmd == program
          cmd.instance_variable_set(:@parent, cmds[cmd.parent_path])
          cmd.parent.commands[cmd.name] = cmd
          cmd.parent.cmds << cmd
          !cmd.parent.commands.key?(cmd.ident) or 
              error "Duplicate command identifier '#{cmd.ident}'", cmd.parent
          cmd.parent.commands[cmd.ident] = cmd
        }
      end
    end
  end
end
