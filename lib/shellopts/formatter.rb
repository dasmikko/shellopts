
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
      DESCRS_ABBR = "ARGS"

      def pass?(words, width)
        words.sum(&:size) + words.size - 1 <= width
      end

      # Render on one line. Compcat multiple descriptions
      def render_single(width)
        long_options = options.map { |option| option.render(:long) }
        short_options = options.map { |option| option.render(:short) }
        compact_options = [OPTIONS_ABBR]
        short_commands = commands.empty? ? [] : ["[#{commands.map(&:name).join("|")}]"]
        compact_commands = [COMMANDS_ABBR]
        args = descrs.size == 1 ? [descrs.text] : [DESCRS_ABBR]

        begin # to be able to use 'break' below
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
      end

      # Render one line for each description
      def render_enum(width)
        long_options = options.map { |option| option.render(:long) }
        short_options = options.map { |option| option.render(:short) }
        compact_options = [OPTIONS_ABBR]
        short_commands = commands.empty? ? [] : ["[#{commands.map(&:name).join("|")}]"]
        compact_commands = [COMMANDS_ABBR]
        args_texts = self.descrs.empty? ? [DESCRS_ABBR] : descrs.map(&:text)

        args_texts.map { |args_text|
          args = [args_text]

          begin # to be able to use 'break' below
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
        }
      end

      # Wrap command but compact multiple descriptions
      def render_multi(width)
        width = 79
        long_options = options.map { |option| option.render(:long) }
        short_options = options.map { |option| option.render(:short) }
        compact_options = [OPTIONS_ABBR]
        short_commands = commands.empty? ? [] : ["[#{commands.map(&:name).join("|")}]"]
        compact_commands = [COMMANDS_ABBR]
        args = self.descrs.size != 1 ? [DESCRS_ABBR] : descrs.map(&:text)

        words = [name] + long_options + short_commands + args
        return [words.join(" ")] if pass?(words, width)
        words = [name] + short_options + short_commands + args
        return [words.join(" ")] if pass?(words, width)

        indent = name.size + 1
        lines = Formatter.wrap(width, indent, long_options)
        lines = ["#{name} " + lines[0]] + Formatter.indent_lines(indent, lines[1..-1])

        commands = pass?(short_commands + args, width - indent) ? short_commands : compact_commands
        lines.concat Formatter.indent_lines(indent, [(commands + args).join(" ")])

        return lines
      end

      def render(format, width)
        case format
          # Force one line. Compact descriptions if needed
          when :single
            render_single(width)

          # One line for each descr
          when :enum
            render_enum(width)
    
          # Wrap if needed but compact descriptions
          when :multi
            render_multi(width)
        else
          raise InterpreterError, "Illegal format: #{format.inspect}"
        end
      end
    end
  end

  module Formatter
    # Number of spaces to use for indentation
    INDENT = 2

    # Maximum width of Command :multi format
    USAGE_MAX_WIDTH = 79 - INDENT 

    # Maximum width of first column in option and command lists
    FIRST_MAX_WIDTH = 40

    # Minimum width of second column in option and command lists
    SECOND_MIN_WIDTH = 50

    def self.brief(program, width = TermInfo.screen_size.last - 3)
      command_width = [width - INDENT, USAGE_MAX_WIDTH].min
      option_briefs = program.option_groups.map { |group| [group.render(:enum), group.brief&.words] }
      command_briefs = program.commands.map { |command| [command.render(:single, width), command.brief&.words] }
      widths = compute_column_widths(width, option_briefs + command_briefs)

      l = []

      if program.brief
        l << "Name:" << "#{indent}#{program.name} - #{program.brief.text}" << ""
      end

      l << "Usage:"
      if program.descrs.size == 1
        l.concat indent_lines(2, program.render(:multi, command_width))
      else
        l.concat indent_lines(2, program.render(:enum, command_width))
      end

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

    def self.wrap(width, curr = 0, words)
      lines = [[]] # Array of lines of array of words
      words.each { |word|
        if curr + 1 + word.size < width
          lines.last << word
          curr += 1 + word.size
        else
          lines << [word]
          curr = word.size
        end
      }
      lines.map! { |words| words.join(" ") } # Flatten into an array of lines
    end

    def self.indent_lines(indent, lines)
      lines.map { |line| "#{' ' * indent}#{line}" }
    end

  private
    def self.indent() ' ' * INDENT end

    def self.compute_column_widths(width, fields)
      first_max = [fields.map { |first, _| first.size }.max, FIRST_MAX_WIDTH].min
      second_max = fields.map { |_, second| second ? second&.map(&:size).sum + second.size : 0 }.max

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

