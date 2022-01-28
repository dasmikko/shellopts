module ShellOpts
  class Lexer
    def self.lex(source)
      lines = source.split("\n").map(&:strip)

      # Skip initial blank lines
      lines = lines.drop_while { |line| line == "" }

      # Split lines into command, option, argument, or text
      res = []
      while line = lines.shift
        if line =~ SCAN_RE
          # Collect following comments
          txts = []
          while lines.first && lines.first !~ SCAN_RE
            txts << lines.shift
          end

          words = line.split(/\s+/)
          while word = words.shift
            type = 
                case word
                  when OPTION_RE
                    "OPT"
                  when COMMAND_PATH_RE
                    "CMD"
                  when "--", ARGUMENT_EXPR_RE
                    word = words.shift if word == "--"
                    args = [word]
                    # Scan arguments
                    while words.first =~ ARGUMENT_EXPR_RE
                      args << words.shift
                    end
                    word = args.join(" ")
                    "ARG"
                  when /^[a-z0-9]/
                    raise CompileError, "Illegal argument: #{word} (should be uppercase)"
                  else
                    raise CompileError, "Illegal syntax: #{line}"
                end
            res << [type, word]
            txts.each { |txt| res << ["TXT", txt] } # Add comments after first command or option
            txts = []
          end
        elsif line =~ /^-|\+/
          raise CompileError, "Illegal short option name: #{line}"
        else
          res << ["TXT", line]
        end
      end
      res
    end
  end
end

