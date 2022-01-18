
module ShellOpts
  # TODO: 
  #   o Change syntax for commands to !command.name. This makes the lexer
  #     simpler, since we only need to scan for '-', '--', '++', '#'. The 
  #     rest will be comments or blank lines
  class Lexer
    attr_reader :source
    attr_reader :tokens

    def initialize(source)
      @source = source
      @source += "\n" if @source[-1] != "\n" # Always terminate source with a newline
    end

    def lex()
      @line, @char = 0, 0
      @i = 0

      # Scan through initial whitespace or comments
      while !eos?
        if curr =~ /\s/
          getchar
        elsif curr == "#"
          getline
        else
          break
        end
      end

      # Generate tokens
      tokens = [Token.new(:program, 0, -1, source)]
      while !eos?
        p head
        tokens << 
            case head
              when /\A[^\S\r\n]*\n/
                Token.new(:blank, *getline)
              when /\A(?:--|\+\+) /
                Token.new(:arguments, *gettext)
              when /\A#/
                Token.new(:brief, *getline)
              when /\A-\w/, /\A--\w/
                Token.new(:option, *getword)
              when /\A[\w\.]+!/
                Token.new(:command, *getword)
            else
              getchar if curr == "\\"
              Token.new(:line,  *getline)
            end
        p tokens.last
      end
      initial_indent = tokens[1]&.char

      # Filter blank lines except when surrounded by comments with the same
      # indent. Included blank lines have their indent adjusted to the indent
      # of the enclosing comments
      tokens.pop while tokens.last.kind == :blank
      wo_blanks = [tokens.shift]
      
      if tokens.size > 0
        tokens[0..-2].each.with_index { |token, i|
          if token.kind == :blank
            p = tokens[i-1]
            n = tokens[i+1]
            next if p.kind != :line || n.kind != :line || p.char != n.char
            token.char = p.char
          end
          wo_blanks << token
        }
        wo_blanks << tokens[-1]
      end

      # Filter outdented briefs (aka. meta comments)
      wo_briefs = [wo_blanks.shift]
      wo_blanks.each { |token|
        wo_briefs << token if token.kind != :brief || token.char >= initial_indent
      }

      @tokens = wo_briefs
    end

    def self.lex(source)
      self.new(source).lex
    end

  protected
    def eos?() @i >= @source.size end
    def line() @line end
    def char() @char end

    # Current character
    def curr() @source[@i] end

    # Next character
    def peek() @source[@i+1] end

    # The remaining source
    def head() @source[@i..-1] end

    # Get a single character
    def getchar()
      return nil if eos?
      if @source[@i] == "\n"
        @line += 1
        @char = 0
      else
        @char += 1
      end
      @source[@i+=1]
    end

    # Get text until whitespace or newline
    def getword() getre /\S/ end

    # Get text until comment or newline
    def gettext() getre /[^#\n]/ end

    # Get text until newline
    def getline() getre /[^\n]/ end

    # Skip over whitespace until (and including) first newline
    def skipws()
      return nil if eos?
      if head =~ /^[^\S\n]*(\n[^\S\n]*)?/m
        if $1
          @line += 1 
          @char = $1.size - 1
        else
          @char += $&.size
        end
        @i += $&.size
      end
    end

  private
    # General get-matching-text method. Return a tuple of the line and character
    # number and the source itself
    def getre(re)
      return nil if eos?
      l, c = @line, @char
      line = @source[@i..-1].each_char.take_while { |char| char =~ re }.join
      @i += line.size
      @char += line.size
      skipws
      [l, c, line.rstrip]
    end
  end
end

