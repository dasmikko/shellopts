
module ShellOpts
  class Line
    attr_reader :source, :line, :char, :text

    def initialize(line, source)
      @line, @source = line, source
      @char = (@source =~ /(\S.*?)\s*$/) || 0
      @text = $1 || ""
    end

    def blank?() @text == "" end

    forward_to :@text, :=~, :!~

    # Split on whitespace while keeping track of character position. Returns
    # array of char, word tuples
    def words
      return @words if @words
      @words = []
      char = self.char
      text.scan(/(\s*)(\S*)/)[0..-2].each { |spaces, word|
        char += spaces.size
        @words << [char, word] if word != ""
        char += word.size
      }
      @words
    end

    def to_s() text end
    def dump() puts "#{line+1}:#{char+1} #{text.inspect}" end
  end

  class Lexer
    COMMAND_RE = /[a-z][a-z._-]*!/

    DECL_RE = /^(?:-|--|\+|\+\+|(?:@(?:\s|$))|(?:[^\\!]\S*!(?:\s|$)))/

    # Match ArgSpec argument words. TODO
    SPEC_RE = /^[^a-z]{2,}$/

    # Match ArgDescr words (should be at least two characters long)
    DESCR_RE = /^[^a-z]{2,}$/

    SECTIONS = %w(DESCRIPTION OPTIONS COMMANDS)

    using Ext::Array::ShiftWhile

    attr_reader :name # Name of program
    attr_reader :source
    attr_reader :tokens

    def initialize(name, source)
      @name = name
      @source = source
      @source += "\n" if @source[-1] != "\n" # Always terminate source with a newline
    end

    def lex
      lines = source[0..-2].split("\n").map.with_index { |line,i| Line.new(i, line) }

      # Skip initial comments and blank lines and compute indent level
      lines.shift_while { |line| line.text == "" || line.text.start_with?("#") && line.char == 0 }
      initial_indent = lines.first&.char

      # Create program token
      @tokens = [Token.new(:program, -1, -1, "#{@name}!")]

      # Used to detect code blocks
      last_nonblank = @tokens.first

      # Process lines
      while line = lines.shift
        # Pass-trough blank lines
        if line.to_s == ""
          @tokens << Token.new(:blank, line.line, line.char, "")
          next
        end
          
        # Ignore meta comments
        if line.char < initial_indent
          next if line =~ /^#/
          error_token = Token.new(:text, line.line, 0, "")
          lexer_error error_token, "Illegal indentation"
        end

        # Line without escape
        source = line.text[(line.text =~ /^\\/ ? 1 : 0)..-1]

        # Code lines
        if last_nonblank.kind == :text && line.char > last_nonblank.char && line !~ DECL_RE
          @tokens << Token.new(:text, line.line, line.char, source)
          lines.shift_while { |line| line.blank? || line.char > last_nonblank.char }.each { |line|
            kind = (line.blank? ? :blank : :text)
            @tokens << Token.new(kind, line.line, line.char, line.text)
          }

        # Sections
        elsif SECTIONS.include?(line.text)
          @tokens << Token.new(:section, line.line, line.char, line.text)

        # Options, commands, usage, arguments, and briefs
        elsif line =~ DECL_RE
          words = line.words
          while (char, word = words.shift)
            case word
              when "@"
                if words.empty?
                  error_token = Token.new(:text, line.line, char, "@")
                  lexer_error error_token, "Empty '@' declaration"
                end
                source = words.shift_while { true }.map(&:last).join(" ")
                @tokens << Token.new(:brief, line.line, char, source)
              when "--" # FIXME Rename argdescr
                @tokens << Token.new(:usage, line.line, char, "--")
                source = words.shift_while { |_,w| w =~ DESCR_RE }.map(&:last).join(" ")
                @tokens << Token.new(:usage_string, line.line, char, source)
              when "++" # FIXME Rename argspec
                @tokens << Token.new(:spec, line.line, char, "++")
                words.shift_while { |c,w| w =~ SPEC_RE and @tokens << Token.new(:argument, line.line, c, w) }
              when /^-|\+/
                @tokens << Token.new(:option, line.line, char, word)
              when /!$/
                @tokens << Token.new(:command, line.line, char, word)
            else
              source = [word, words.shift_while { |_,w| w !~ DECL_RE }.map(&:last)].join(" ")
              @tokens << Token.new(:brief, line.line, char, source)
            end
          end

        # Paragraph lines
        else
          @tokens << Token.new(:text, line.line, line.char, source)
        end

        last_nonblank = @tokens.last
      end
      @tokens
    end

    def self.lex(name, source)
      Lexer.new(name, source).lex
    end

    def lexer_error(token, message) raise LexerError, "#{token.pos} #{message}" end
  end
end

