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
      def puts_descr
        puts Ansi.bold(render(:multi))
        indent {
          if description.any?
            description.each { |descr|
              descr.puts_descr
              puts if descr != description.last
            }
          elsif brief
            brief.puts_descr
          end
        }
      end
    end

    # brief one-line commands should optionally use compact options
    class Command
      using Ext::Array::Wrap

      def puts_usage(bol: false)
        if descrs.size == 0
          print (lead = Formatter.command_prefix || "")
          indent(lead.size, ' ', bol: bol && lead == "") { 
            puts render2(:multi, Formatter::USAGE_MAX_WIDTH) 
          }
        else
          lead = Formatter.command_prefix || ""
          descrs.each { |descr|
            print lead
            puts render2(:single, Formatter::USAGE_MAX_WIDTH, args: [descr.text]) 
          } 
        end
      end

      def puts_brief
        width = Formatter.rest
        option_briefs = option_groups.map { |group| [group.render(:enum), group.brief&.words] }
        command_briefs = commands.map { |command| [command.render2(:single, width), command.brief&.words] }
        widths = Formatter::compute_columns(width, option_briefs + command_briefs)

        if brief
          puts brief
          puts
        end

        puts "Usage"
        indent { puts_usage(bol: true) }

        if options.any?
          puts
          puts "Options"
          indent { Formatter::puts_columns(widths, option_briefs) }
        end

        if commands.any?
          puts
          puts "Commands"
          indent { Formatter::puts_columns(widths, command_briefs) }
        end
      end

      def puts_descr(prefix, brief: !self.brief.nil?, name: :path)
        puts Ansi.bold([prefix, render2(:single, Formatter.rest)].flatten.compact.join(" "))
        indent {
          if brief
            puts self.brief.words.wrap(Formatter.rest)
          else
            newline = false
            children.each { |child|
              puts if newline
              newline = true

              if child.is_a?(Command)
                child.puts_descr(prefix, name: :path)
                newline = false
               else
                child.puts_descr
              end
            }
          end
        }
      end

      def puts_help
        puts Ansi.bold "NAME"
        full_name = [Formatter::command_prefix, name].join
        indent { puts brief ? "#{full_name} - #{brief}" : full_name }
        puts

        puts Ansi.bold "USAGE"
        indent { puts_usage(bol: true) }

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
#             prefix = child.parent != self ? nil : child.supercommand&.name
              prefix = child.supercommand == self ? nil : child.supercommand&.name
              child.puts_descr(prefix, brief: false, name: :path)
              newline = true
             else
              child.puts_descr
            end
          }

          # Also emit commands not declared in nested scope
          (commands - children.select { |child| child.is_a?(Command) }).each { |cmd|
            puts if newline
            newline = true
            prefix = cmd.supercommand == self ? nil : cmd.supercommand&.name
            cmd.puts_descr(prefix, brief: false, name: path)
          }
        }
      end
    end

    class Program
      using Ext::Array::Wrap
    end

    class DocNode
      def puts_descr() puts lines end
    end

    module WrappedNode
      def puts_descr(width = Formatter.rest) puts lines(width) end
    end

    class Code
      def puts_descr() indent { super } end
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
    BRIEF_COL1_MIN_WIDTH = 6

    # Maximum width of first column in brief option and command lists
    BRIEF_COL1_MAX_WIDTH = 40

    # Minimum width of second column in brief option and command lists
    BRIEF_COL2_MAX_WIDTH = 50

    # Indent to use in help output
    HELP_INDENT = 4

    # Command prefix when subject is a sub-command
    def self.command_prefix() @command_prefix end

    # Usage string in error messages
    def self.usage(subject)
      subject = Grammar::Command.command(subject)
      @command_prefix = subject.ancestors.map { |node| node.name + " " }.join
      setup_indent(1) {
        print lead = "#{USAGE_STRING}: "
        indent(lead.size, ' ', bol: false) { subject.puts_usage }
      }
    end

#   # TODO
#   def self.usage=(usage_lambda)
#   end

    # When the user gives a -h option
    def self.brief(command)
      command = Grammar::Command.command(command)
      @command_prefix = command.ancestors.map { |node| node.name + " " }.join
      setup_indent(BRIEF_INDENT) { command.puts_brief }
    end

#   # TODO
#   def self.brief=(brief_lambda)
#   end

    # When the user gives a --help option
    def self.help(subject)
      subject = Grammar::Command.command(subject)
      @command_prefix = subject.ancestors.map { |node| node.name + " " }.join
      setup_indent(HELP_INDENT) { subject.puts_help }
    end

    # Short-hand to get the Grammar::Command object
    def self.command_of(obj)
      constrain obj, Grammar::Command, ::ShellOpts::Program
      obj.is_a?(Grammar::Command) ? obj : obj.__grammar__
    end

#   # TODO
#   def self.help_w_lambda(program)
#     if @help_lambda
#       #
#     else
#       program = Grammar::Command.command(program)
#       setup_indent(HELP_INDENT) { program.puts_descr }
#     end
#   end
#
#   def self.help=(help_lambda) @help_lambda end

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
      first_max = [
        (fields.map { |first, _| first.size } + [BRIEF_COL1_MIN_WIDTH]).max, 
        BRIEF_COL1_MAX_WIDTH
      ].min
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
    # TODO Get rid of?
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

