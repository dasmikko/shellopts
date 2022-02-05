
# Option rendering
#   -a, --all                   # Only used in brief and doc formats (enum)
#   --all                       # Only used in usage (long)
#   -a                          # Only used in usage (short)
#
# Option group rendering
#   -a, --all  -b, --beta       # Only used in brief formats (enum)
#   --all --beta                # Used in usage (long)
#   -a -b                       # Used in usage (short)
#
#   -a, --all                   # Only used in doc format (:multi)
#   -b, --beta
#
# Command rendering
#   
#   cmd --all --beta [cmd1|cmd2] ARGS   # Single-line formats (:single)
#   cmd -a -b [cmd1|cmd2] ARGS
#
#   cmd --all --beta                    # Multi-line formats (:multi)
#       [cmd1|cmd2] ARGS
#
#   
require 'terminfo'
module ShellOpts
  module Grammar
    class Option
      def render(format)
        constrain format, :enum, :long, :short
        case format
          when :enum; names.join(", ")
          when :long; name
          when :short; short_names.first || name
        else
          raise InterpreterError, "Illegal format: #{format.inspect}"
        end + (argument? ? "=#{argument_name}" : "")
      end
    end

    class OptionGroup
      def render(format)
        options.map { |option| option.render(format) }.join(" ")
      end
    end

    # brief one-line commands should optionally use compact options
    class Command
      OPTIONS_ABBR = "<options>"
      COMMANDS_ABBR = "<commands>"

      def pass?(words, width)
        words.sum(&:size) + words.size - 1 <= width
      end

      def render(format, width)
        case format
          when :single
            begin
              long_options = options.map { |option| option.render(:long) }
              short_options = options.map { |option| option.render(:short) }
              compact_options = [OPTIONS_ABBR]
              short_commands = commands.empty? ? [] : ["[#{commands.map(&:name).join("|")}]"]
              compact_commands = [COMMANDS_ABBR]
              args = [descrs.first&.text].compact

              words = [name] + long_options + short_commands + args
              break if pass?(words, width)
              words = [name] + short_options + short_commands + args
              break if pass?(words, width)
              words = [name] + long_options + compact_commands + args
              break if pass?(words, width)
              words = [name] + short_options + compact_commands + args
              break if pass?(words, width)
              words = [name] + compact_options + short_commands + args
              break if pass?(words, width)
              words = [name] + compact_options + compact_commands + args
            end while false
            words.join(" ")
          when :multi
            raise NotImplementedError
        else
          raise InterpreterError, "Illegal format: #{format.inspect}"
        end
      end
    end
  end

  module Formatter2
    INDENT = "  "

    FIRST_MAX_WIDTH = 40
    SECOND_MIN_WIDTH = 50

    def self.brief(program, width = TermInfo.screen_size.last - 3)
      l = []

      l << [program.name, program.brief].join(" - ") << "" if program.brief
      l << "Usage:" << "#{INDENT}#{program.render(:single, width)}"

      option_briefs = program.option_groups.map { |group| [group.render(:enum), group.brief&.words] }
      command_briefs = program.commands.map { |command| [command.render(:single, width), command.brief&.words] }
      widths = compute_column_widths(width, option_briefs + command_briefs)

      if !program.options.empty?
        l << "" << "Options:"
        l.concat indent_lines(2, columnize(widths, option_briefs))
      end

      if !program.commands.empty?
        l << "" << "Commands:"
        l.concat indent_lines(2, columnize(widths, command_briefs))
      end

      l
    end

  private
    def self.indent_lines(indent, lines)
      lines.map { |line| "#{' ' * indent}#{line}" }
    end

    def self.wrap(width, words)
      lines = [[]] # Array of lines of array of words
      curr = 0
      words.each { |word|
        if curr + 1 + word.size < width
          lines.last << word
          curr += 1 + word.size
        else
          lines << [word]
          curr = word.size
        end
      }
      lines.map! { |words| words.join(" ") } # Flatten into an array of line
    end

    def self.compute_column_widths(width, fields)
      first_max = [fields.map { |first, _| first.size }.max, FIRST_MAX_WIDTH].min
      second_max = fields.map { |_, second| second&.size || 0 }.sum + fields.size

      if first_max + 2 + second_max <= width
        first_width = first_max
        second_width = second_max
      elsif first_max + 2 + SECOND_MIN_WIDTH <= width
        first_width = first_max
        second_width = width - first_width - 2
      else
        first_width = [width - 2 - SECOND_MIN_WIDTH, FIRST_MAX_WIDTH].min
        second_width = SECOND_MIN_WIDTH
      end

      [first_width, second_width]
    end

    def self.columnize(widths, fields)
      l = []
      first_width, second_width = *widths
      second_col = first_width + 2

      for (first, second) in fields
        if first.size > first_width
          l << first
          l.concat indent_lines(second_col, wrap(second_width, second)) if second
        else
          l << first
          if second
            wrapped_lines = wrap(second_width, second)
            l.last.concat ' ' * (second_col - first.size) + wrapped_lines.shift
            l.concat indent_lines(second_col, wrapped_lines)
          end
        end
      end

      l
    end

  end
end

__END__

-v, --verbose -h, --help --version                   
Multi option line. Option group. Lorem
                                                       Multi option line. Option group. Lorem

-v, --verbose -h, --help --version   
        --force-color, --force-colour  

module ShellOpts
  module Grammar
    class Option
      def self.abbr_word() "<options>" end
      def abbr_word() self.class.abbr_word end

      def compact_word
        compact_name = short_names.first || name
        "#{compact_name}" + (argument? ? "=#{argument_name}" : "") 
      end

      def short_word
        "#{name}" + (argument? ? "=#{argument_name}" : "") 
      end

      def long_word
        names.join(", ") + (argument? ? "=#{argument_name}" : "") 
      end

      def render(format)
        constrain format, :enum, :long, :short
        case format
          when :enum; names.join(", ")
          when :long; name
          when :short; short_names.first || name
        else
          raise InterpreterError, "Illegal format: #{format.inspect}"
        end + (argument? ? "=#{argument_name}" : "")
      end
    end

    class OptionGroup
      def brief_words() brief&.words || [] end
      def descr_words() [] end # FIXME

      def compact_words
        [options.first.compact_word]
      end

      def short_words
        options.map(&:short_word)
      end

      def long_words
        options.map(&:long_word)
      end
    end

    # brief one-line commands should optionally use compact options
    class Command
      def self.abbr_word() "<commands>" end
      def abbr_word() self.class.abbr_word end

      def short_option_words
        options.map(&:short_word)
      end

      def long_option_words
        options.map(&:long_word)
      end

      def brief
      end

    end
  end

  module Formatter2
    INDENT = "  "

    def self.oneline_command(command)
      [[
        command.name,
        command.options.empty? ? nil : Grammar::Option.abbr_word, 
        command.commands.empty? ? nil : Grammar::Command.abbr_word
      ].compact.join(" ")]
    end

    def self.multiline_command(command)
      [[
        command.name, 
        command.options.empty? ? nil : Grammar::Option.abbr_word, 
        command.commands.empty? ? nil : Grammar::Command.abbr_word
      ].compact.join(" ")]
    end

    def self.brief(program)
      l = []

      l << [program.name, program.brief].join(" - ") << "" if program.brief
      l << "Usage:" << multiline_command(program).map { |line| "#{INDENT}#{line}" }
      
      if !program.options.empty?
        l << "" << "Options:"
        program.options.each { |option|
          # TODO handle option groups
          # TODO compute if option+brief can be on one line

          l << [INDENT + option.long_word, option.group.brief&.text].compact.join(" ")
        }
      end

      if !program.commands.empty?
        l << "" << "Commands:"
        program.commands.each { |command|
          # TODO compute if option+brief can be on one line

          l << (INDENT + oneline_command(command).first + " " + (command.brief || ""))
        }
      end

      l

#     s = StringIO.new
#
#     s.puts [program.name, program.brief].compact.join(" - ")
#     s.puts
#     s.puts "Usage:"
#     s.puts program.multiline
#     
#     if !program.options.empty?
#       s.puts
#       s.puts "Options:"
#       program.options.each { |option|
#         # handle option groups
#         s.indent {
#           # compute if option+brief can be on one line
#           s.puts option.long + " " + option.brief
#         }
#       }
#     end
#     
#     if !program.commands.empty?
#       s.puts
#       s.puts "Commands:"
#       program.commands.each { |command|
#         s.indent {
#           # compute if option+brief can be on one line
#           s.puts command.oneline + " " + command.brief
#         }
#       }
#     end
    end

    def brief_command()
      # call brief with program name as initial
    end
  end
end

__END__








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
    def render_command_short(width: WIDTH, indent: 0, initial: 0)
      
      
      
    end


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

  def self.command_short
    
  end

  # Format can be :enum, :brief, :long
  def self.render_option(option, format)
    case format
      when :enum; "#{name}" + (argument? ? "=#{argument_name}" : "") 
      when :brief; [render_option(option, :enum), option.brief]
      when :long;


  end

end










