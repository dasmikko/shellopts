require 'terminfo'

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
  module Grammar
    class Option
      # Formats:
      #
      #   :enum     -a, --all
      #   :long     --all
      #   :short    -a
      #
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
      # Formats:
      #     
      #     :enum   -a, --all -r, --recursive
      #     :long   --all --recursive
      #     :short  -a -r
      #     :multi  -a, --all
      #             -r, --recursive
      #
      def render(format)
        constrain format, :enum, :long, :short, :multi
        if format == :multi
          options.map { |option| option.render(:enum) }.join("\n")
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

      # Format can be one of :single, :enum, or :multi. :single force one-line
      # output and compacts options and commands if needed. :enum outputs a
      # :single line for each argument specification/description, :multi tries
      # one-line output but wrap options if needed. Multiple argument
      # specifications/descriptions are always compacted
      #
      def render(format, width)
        case format
          when :single; render_single(width)
          when :enum; render_enum(width)
          when :multi; render_multi(width)
        else
          raise InterpreterError, "Illegal format: #{format.inspect}"
        end
      end

    protected
      # Force one line. Compact descriptions and options if needed
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

      # Render one line for each argument specification/description
      def render_enum(width)
        # TODO: Also refactor args here
        args_texts = self.descrs.empty? ? [DESCRS_ABBR] : descrs.map(&:text)
        args_texts.map { |args_text| render_single(width, args: [args_text]) }
      end

      # Try to keep on one line but wrap options if needed. Multiple argument
      # specifications/descriptions are always compacted
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

      # Helper method that returns true if words can fit in width characters
      def pass?(words, width)
        words.sum(&:size) + words.size - 1 <= width
      end
    end
  end
end
