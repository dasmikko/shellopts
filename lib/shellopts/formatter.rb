require 'terminfo'

# TODO: Move to ext/indented_io.rb
module IndentedIO
  class IndentedIO
    def margin() combined_indent.size end
  end
end

module ShellOpts
  module Grammar
    class Node
      def puts_help() end
      def puts_usage() end
    end

    class Option
    end

    class OptionGroup
      def puts_help
        puts Ansi.bold(render(:multi))
        indent {
          if description.any?
            description.each { |descr|
              descr.puts_help
              puts if descr != description.last
            }
          elsif brief
            brief.puts_help
          end
        }
      end
    end

    # brief one-line commands should optionally use compact options
    class Command
      using Ext::Array::Wrap

      def puts_help(brief = !self.brief.nil?)
        if parent&.path != command&.path
          puts Ansi.bold([path[0..-2], render(:single, Formatter.rest)].flatten.join(" "))
        else
          puts Ansi.bold(render(:single, Formatter.rest))
        end
        indent {
          if brief
            puts self.brief.words.wrap(Formatter.rest)
          else
            newline = false
            children.each { |child|
              puts if newline
              newline = true

              if child.is_a?(Command)
                child.puts_help(false)
                newline = false
               else
                child.puts_help
              end
            }
          end
        }
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
        puts Ansi.bold "NAME"
        indent { puts_name }
        puts

        puts Ansi.bold "USAGE"
        indent { puts_usage }

        section = {
          Paragraph => "DESCRIPTION",
          OptionGroup => "OPTIONS",
          Command => "COMMANDS"
        }

        newline = false # True if a newline should be printed before child 
        indent {
          children.each { |child|
            if child.is_a?(Section)
              puts
              indent(-1).puts Ansi.bold child.name
              section.delete_if { |_,v| v == child.name }
              section.delete(Paragraph)
              newline = false
              next
            elsif s = section[child.class]
              puts  
              indent(-1).puts Ansi.bold s
              section.delete(child.class)
              section.delete(Paragraph)
              newline = false
            else
              puts if newline
              newline = true
            end

            if child.is_a?(Command)
              child.puts_help(false)
              newline = true
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
      def puts_help() puts lines end
    end

    module WrappedNode
      def puts_help(width = Formatter.rest) puts lines(width) end
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

    # TODO
    def self.usage=(usage_lambda)
    end

    # When the user gives a -h option
    def self.brief(program)
      program = Grammar::Program.program(program)
      setup_indent(BRIEF_INDENT) { program.puts_brief }
    end

    # TODO
    def self.brief=(brief_lambda)
    end

    # When the user gives a --help option
    def self.help(program)
      program = Grammar::Program.program(program)
      setup_indent(HELP_INDENT) { program.puts_help }
    end

#   def self.help_w_lambda(program)
#     if @help_lambda
#       #
#     else
#       program = Grammar::Program.program(program)
#       setup_indent(HELP_INDENT) { program.puts_help }
#     end
#   end

    # TODO
    def self.help=(help_lambda) @help_lambda end

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

