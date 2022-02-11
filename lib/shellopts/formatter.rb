require 'terminfo'

module IndentedIO
  class IndentedIO
    attr_reader :levels
    def margin() combined_indent.size end
  end
end

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
#   cmd --all --beta [cmd1|cmd2] ARG1 ARG2    # Single-line formats (:single)
#   cmd --all --beta [cmd1|cmd2] ARGS...     
#   cmd -a -b [cmd1|cmd2] ARG1 ARG2
#   cmd -a -b [cmd1|cmd2] ARGS...
#
#   cmd -a -b [cmd1|cmd2] ARG1 ARG2           # One line for each argument description (:enum)
#   cmd -a -b [cmd1|cmd2] ARG3 ARG4           # (used in the USAGE section)
#
#   cmd --all --beta                          # Multi-line formats (:multi)
#       [cmd1|cmd2] ARG1 ARG2
#   cmd --all --beta
#       <commands> ARGS
#   
module ShellOpts
  INDENT = 2
  HELP_INDENT = 4

  module Grammar
    class Node
      def puts_help() end
      def puts_usage() end
    end

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
      def puts_help
        puts Ansi.bold(render(:enum))
        indent {
          if description.any?
            description.each { |descr|
              descr.puts_help
            }
          elsif brief
            brief.puts_help
          else
            puts
          end
        }
      end

      def render(format)
        constrain format, :enum, :long, :short, :multi
        if format == :multi
          options.map { |option| option.render(:long) }.join("\n")
        else
          options.map { |option| option.render(format) }.join(" ")
        end
      end
    end

    # brief one-line commands should optionally use compact options
    class Command
      using Ext::Array::Wrap

      OPTIONS_ABBR = "[OPTIONS]"
      COMMANDS_ABBR = "[COMMANDS]"
      DESCRS_ABBR = "ARGS..."

      # Helper method that returns true if words can fit in width characters
      def pass?(words, width)
        words.sum(&:size) + words.size - 1 <= width
      end

      # Render on one line. Compact multiple argument descriptions
      def render_single(width, args: nil)
        long_options = options.map { |option| option.render(:long) }
        short_options = options.map { |option| option.render(:short) }
        compact_options = [OPTIONS_ABBR]
        short_commands = commands.empty? ? [] : ["[#{commands.map(&:name).join("|")}]"]
        compact_commands = [COMMANDS_ABBR]

        # TODO: Refactor and implement recursive detection of any argument
        args ||= 
            case descrs.size
              when 0; args = []
              when 1; [descrs.first.text]
              else [DESCRS_ABBR]
            end
          
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

      # Render one line for each argument description
      def render_enum(width)
        # TODO: Also refactor args here
        args_texts = self.descrs.empty? ? [DESCRS_ABBR] : descrs.map(&:text)
        args_texts.map { |args_text|
          render_single(width, args: [args_text])
        }
      end

      # Wrap options and commands and compact multiple descriptions
      def render_multi(width)
        long_options = options.map { |option| option.render(:long) }
        short_options = options.map { |option| option.render(:short) }
        short_commands = commands.empty? ? [] : ["[#{commands.map(&:name).join("|")}]"]
        compact_commands = [COMMANDS_ABBR]
        args = self.descrs.size != 1 ? [DESCRS_ABBR] : descrs.map(&:text)

        # On one line
        words = long_options + short_commands + args
        return [words.join(" ")] if pass?(words, width)
        words = short_options + short_commands + args
        return [words.join(" ")] if pass?(words, width)

        # On multiple lines
        options = long_options.wrap(width)
        commands = [[short_commands, args].join(" ")]
        return options + commands if pass?(commands, width)
        options + [[compact_commands, args].join(" ")]
      end

      def render(format, width)
        case format
          # Force one line. Compact descriptions if needed
          when :single
            render_single(width)

          # One line for each descr
          when :enum
            render_enum(width)
    
          # Wrap if needed
          when :multi
            render_multi(width)
        else
          raise InterpreterError, "Illegal format: #{format.inspect}"
        end
      end
    end

    class Program
      using Ext::Array::Wrap

      def puts_single
        puts render(:multi, Formatter::USAGE_MAX_WIDTH)
      end
    
      def puts_brief
        width = Formatter.rest
        option_briefs = option_groups.map { |group| [group.render(:enum), group.brief&.words] }
        command_briefs = commands.map { |command| [command.render(:single, width), command.brief&.words] }
        widths = Formatter::compute_columns(width, option_briefs + command_briefs)

        if brief
          puts "Name:"
          indent { puts_name }
          puts
        end

        puts "Usage:"
        indent { puts_usage }

        if options.any?
          puts
          puts "Options:"
          indent { Formatter::puts_columns(widths, option_briefs) }
        end

        if commands.any?
          puts
          puts "Commands:"
          indent { Formatter::puts_columns(widths, command_briefs) }
        end
      end

      def puts_help
        puts "NAME"
        indent { puts_name }
        puts

        puts "USAGE"
        indent { puts_usage }
        puts

        section = {
          Paragraph => "DESCRIPTION",
          OptionGroup => "OPTIONS",
          Command => "COMMANDS"
        }

        indent {
          children.each { |child|
            if child.is_a?(Section)
              indent(-1).puts child.name
              section.delete_if { |_,v| v == child.name }
              section.delete(Paragraph)
            elsif s = section[child.class]
              indent(-1).puts s
              section.delete(child.class)
              section.delete(Paragraph)
            end

            if child.is_a?(Command)
              puts Ansi.bold(child.render(:single, Formatter.rest))
              indent { puts child.brief.words.wrap(Formatter.rest) } if brief
              puts if child != children.last
             else
              child.puts_help
            end
          }
        }
      end

      def puts_name
        puts brief ? "#{name} - #{brief}" : name
      end

      def puts_usage
        if descrs.size == 1
          print lead = "#{name} "
          indent(lead.size, ' ', bol: false) { puts render(:multi, Formatter::USAGE_MAX_WIDTH) }
        else
          puts render(:enum, Formatter::USAGE_MAX_WIDTH)
        end
      end
    end

    class DocNode
      def puts_help() puts lines; puts end
    end

    module WrappedNode
      def puts_help(width = Formatter.rest) puts lines(width); puts end
    end

    class Code
      def puts_help() indent { super } end
    end
  end

  class Formatter
    using Ext::Array::Wrap

    # Right margin
    MARGIN_RIGHT = 3

    # String for 'Usage' in error messages
    USAGE_STRING = "Usage"

    # Indent to use in usage output
    USAGE_INDENT = USAGE_STRING.size

    # Width of usage (after usage string)
    USAGE_MAX_WIDTH = 70

    # Indent to use in brief output
    BRIEF_INDENT = 2

    # Number of characters between columns in brief output
    BRIEF_COL_SEP = 2

    # Maximum width of first column in brief option and command lists
    BRIEF_COL1_MAX_WIDTH = 40

    # Minimum width of second column in brief option and command lists
    BRIEF_COL2_MAX_WIDTH = 50

    # Indent to use in help output
    HELP_INDENT = 4

    # Usage string in error messages
    def self.usage(program)
      setup_indent(1) {
        program = Grammar::Program.program(program)
        print lead = "#{USAGE_STRING}: "
        indent(lead.size, ' ', bol: false) { program.puts_single }
      }
    end

    def self.brief(program)
      program = Grammar::Program.program(program)
      setup_indent(BRIEF_INDENT) { program.puts_brief }
    end

    # --puts_help 
    def self.help(program)
      program = Grammar::Program.program(program)
      setup_indent(HELP_INDENT) { program.puts_help }
    end

    def self.puts_columns(widths, fields)
      l = []
      first_width, second_width = *widths
      second_col = first_width + 2

      for (first, second) in fields
        if first.size > first_width
          puts first
          indent(first_width + BRIEF_COL_SEP, ' ') { puts second.wrap(second_width) } if second
        elsif second
          printf "%-#{first_width + BRIEF_COL_SEP}s", first
          indent(first_width, bol: false) { puts second.wrap(second_width) }
        else
          puts first
        end
      end
    end

    def self.compute_columns(width, fields)
      first_max = [fields.map { |first, _| first.size }.max, BRIEF_COL1_MAX_WIDTH].min
      second_max = fields.map { |_, second| second ? second&.map(&:size).sum + second.size - 1: 0 }.max

      if first_max + BRIEF_COL_SEP + second_max <= width
        first_width = first_max
        second_width = second_max
      elsif first_max + BRIEF_COL_SEP + BRIEF_COL2_MAX_WIDTH <= width
        first_width = first_max
        second_width = width - first_width - BRIEF_COL_SEP
      else
        first_width = [width - BRIEF_COL_SEP - BRIEF_COL2_MAX_WIDTH, BRIEF_COL1_MAX_WIDTH].min
        second_width = BRIEF_COL2_MAX_WIDTH
      end

      [first_width, second_width]
    end

    def self.width()
      @width ||= TermInfo.screen_width - MARGIN_RIGHT
    end

    def self.rest() width - $stdout.margin end

  private
    def self.setup_indent(indent, &block)
      default_indent = IndentedIO.default_indent
      begin
        IndentedIO.default_indent = " " * indent
        indent(0) { yield } # Ensure IndentedIO is on the top of the stack so we can use $stdout.levels
      ensure
        IndentedIO.default_indent = default_indent
      end
    end
  end
end

