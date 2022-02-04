module ShellOpts
  module Grammar
    class Option
      def literal() 
        @literal ||= "#{name}" + (argument? ? "=#{argument_name}" : "") 
      end
    end

    class Command
      def literal() name end
#     def format() 
#       "#{name} " + (options + commands + descrs).map(&:format).join(" ")
#     end
    end

    class ArgDescr
      def literal() token.to_s end
#     def format()
#       token
#     end
    end
  end

  # main -a -b -c ARG1 ARG2
  # main subcmd -d ARG11 ARG22


  class Formatter
    WIDTH=79
    DEFAULT_INITIAL = "Usage:".size
    SHORT_COMMANDS_STR = "<commands>"

    def self.wrap(words, width = WIDTH, indent: 0, initial: 0)
      wrap_indent(words, width, indent: indent, initial: initial).first
    end

    def self.wrap_indent(words, width = WIDTH, indent: 0, initial: 0)
      lines = [[]]
      curr_indent = initial - 1 # -1 makes the if-statement simpler
      words.each { |word|
        if (curr_indent += 1 + word.size) > width
          lines << []
          curr_indent = indent + word.size
        end
        lines.last << word
      }
      lines = lines.map! { |words| words.join(" ") }
      str = lines.join("\n#{' '*indent}")
      indent = indent + lines.last.size
      [str, indent]
    end

    # Render "usage" string
    #
    #
    # Usage: main --lots-of-global-options ...
    #             <command>|<command>|... ARGS
    #             ^max upto 79 characters wide. Then just '<command>'
    #
    #
    #
    # Split into multiple lines if command has subcommands with options or
    # usage strings
    #
    # When Empty subcommands are rendered as bracketed list ([a|b])
    # [sub|another_sub]
    #
    # If command is rendered over multiple lines and it has options:
    #   
    #   main -a -b -c
    #   main [options] subcmd -d -e -f 
    #   main [options] another -g
    #
    #   main -a -b -c [subcmd...|another]
    #
    # Algorithm: Group by #usage, then by #options
    #
    # TODO: Check no-options, no-command, and no-args case(s)
    def self.usage_string(command, width: WIDTH, indent: 0, initial: DEFAULT_INITIAL)
      if command.descrs.size <= 1
        name = command.literal
        name_size = 1 + name.size

        initial = indent + initial
        indent = initial + name_size + 1
        indent_str = ' '*indent

        options = command.options.empty? ? nil : command.options
        options_names = options&.map(&:literal)
        options_size = options ? 1 + options_names.map(&:size).sum + options_names.size - 1 : 0

        commands = command.commands.empty? ? nil : command.commands
        commands_list = commands&.map(&:literal)
        commands_short_str = SHORT_COMMANDS_STR
        commands_short_size = commands ? 1 + commands_short_str.size : 0
        commands_long_str = commands && "["+ commands_list.join("|") + "]"
        commands_long_size = commands ? 1 + commands_long_str.size : 0

        arguments = command.descrs.empty? ? nil : command.descrs[0..0].map(&:literal) # FIXME
        arguments_list = arguments
        arguments_size = arguments ? 1 + arguments_list.first.size : 0

        if initial + name_size + options_size + commands_long_size + arguments_size <= width
          r = [name, options_names, commands_long_str, arguments_list].flatten.compact.join(" ")
        elsif initial + options_size + commands_short_size + arguments_size <= width
          [name, options_names, commands_short_str, arguments_list].flatten.compact.join(" ")
        else
          str = [
              name, 
              options && Formatter.wrap(options_names, width, indent: indent, initial: indent)
          ].flatten.compact.join(" ")

          rest_str =
              if commands_long_size + commands_short_size + arguments_size > 0
                if initial + commands_long_size + arguments_size <= width
                  [commands_long_str, arguments_list]
                else
                  [commands_short_str, arguments_list]
                end.flatten.compact.join(" ")
              else
                nil
              end

          [str, rest_str].compact.join("\n#{indent_str}")
        end
      else
        descrs.join("FIXME")
      end
    end

    # brief_format:
    #   brief_name
    #   brief_usage
    #   for each option
    #     brief_option
    #   end
    #   for each command
    #     brief_command
    #   end

    # One-line format in prioritized order
    # ------------------------------------
    #
    #   cmd -a -b -c [CMD|CMD] ARGS
    #   cmd -a -b -c <command> ARGS
    #   cmd <options> [CMD|CMD] <ARGS>
    #   cmd <options> <command> <ARGS>
    #
    # Multiline format
    # ----------------
    #
    #   cmd -a -b -c [CMD|CMD] ARGS   # <- only if no subcommand options or arguments
    #
    #   cmd -a -b -c <command> ARGS
    #       subcmd -e -f -g ARGS
    #       subcmd -h -i -j ARGS
    #
    #   cmd -a -b -c 
    #       -d -e
    #       [CMD|CMD] ARGS
    #
    #   cmd -a -b -c 
    #       -d -e
    #       <command> ARGS
    #
    # Brief format
    # ------------
    #
    #   Name - Brief
    #
    #   Usage: 
    #     cmd -a -b -c [CMD|CMD] ARGS
    #
    #   Options:
    #     -a                    Brief
    #     -b                    Brief
    #     -c                    Brief
    #
    #   Commands:
    #     CMD --opts ARGS       Brief
    #     CMD --opts ARGS_THAT_TAKES_UP_A_LOT_OF_SPACE       
    #                           Brief
    #
    # Brief Command
    #     CMD --opts ARGS       Brief
    #     CMD --opts ARGS_THAT_TAKES_UP_A_LOT_OF_SPACE       
    #                           Brief
    #
    # Brief Option
    #   -a            Brief
    #   -b=a_very_long_option
    #                 Brief
    #    
    #
    # Doc format
    # ----------
    #
    #   Name
    #     Name - Brief
    #
    #   Usage:
    #     cmd -a -b -c [CMD|CMD] ARGS
    #
    #   Description
    #     Descr
    #
    #   Options:
    #     -a
    #       Descr
    #     -b
    #       Descr
    #     -c
    #       Descr
    #
    #   Commands:
    #     CMD -d -e -f ARGS
    #       Descr
    #
    #       -d
    #         Descr
    #       -e
    #         Descr
    #       -f 
    #         Descr
    #
    #     CMD -g -h -i ARGS
    #       Descr
    #
    #       -g
    #         Descr
    #       -h
    #         Descr
    #       -i 
    #         Descr
    #
    
    
    def self.usage_lines(command, width: WIDTH, indent: 0, initial: DEFAULT_INITIAL)
      if commands.commands.size <= 1
        usage_string(command, width: WIDTH, indent: 0, initial: DEFAULT_INITIAL)
      else
        "TODO"
      end
    end

    # Formats
    #   short - on one line no matter what
    #   brief - on multiple lines, options and commands are separate
    #   long - everything
    #   doc - everything
#   def render_command_short(width: WIDTH, indent: 0, initial: 0)
#     
#     
#     
#   end


    # TODO TODO TODO
    def self.option_help(command, width: WIDTH, indent: 0)
      lines = []
      command.__grammar__.options.map { |option|
        lines << option.name
        words = option.children.map(&:text).join(" ").split(" ")
        p option.children.size
        p words
        lines << wrap_indent(words, indent: 3)
      }
      lines.join("\n")
    end

    def self.option_brief(command, width: WIDTH, indent: 0)
      
    end
  end

# def self.command_short
#   
# end

# # Format can be :enum, :brief, :long
# def self.render_option(option, format)
#   case format
#     when :enum; "#{name}" + (argument? ? "=#{argument_name}" : "") 
#     when :brief; [render_option(option, :enum), option.brief]
#     when :long;
#   end
#
#
# end

end










