
module ShellOpts
  class Line
    attr_reader :source, :line, :char, :text

    def initialize(line, source)
      @line, @source = line, source
      @char = (@source =~ /(\S.*?)\s*$/) || 0
      @text = $1 || ""
    end

    forward_to :@text, :=~

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
    DECL_RE = /^(?:-|--|\+|\+\+|!|#)/

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

      # Skip initial comments and blank lines
      lines.shift_while { |line| line =~ /^(?:#.*)?$/ }
      initial_indent = lines.first.char

      tokens = [Token.new(:program, 0, -1, @name)]
      while line = lines.shift
        # Pass-trough blank lines
        if line.to_s == ""
          tokens << Token.new(:blank, line.line, line.char, "")
          next
        end
          
        # Ignore meta comments
        if line.char < initial_indent
          next if line =~ /^#/
          raise LexerError, "Illegal indent in line #{line.line+1}"
        end

        # Options, commands, usage, arguments, and briefs
        if line =~ DECL_RE
          words = line.words
          while (char, word = words.shift)
            case word
              when /^#/
                source = words.shift_while { true }.map(&:last).join(" ")
                tokens << Token.new(:brief, line.line, char, source)
              when "--"
                source = words.shift_while { |_,w| w !~ DECL_RE }.map(&:last).join(" ")
                tokens << Token.new(:usage, line.line, char, source)
              when "++"
                tokens << Token.new(:spec, line.line, char, "++")
                words.shift_while { |c,w| w !~ DECL_RE && tokens << Token.new(:arg, line.line, c, w) }
              when /^-|\+/
                tokens << Token.new(:option, line.line, char, word)
              when /^!/
                tokens << Token.new(:command, line.line, char, word)
            else
              raise InternalError, "Illegal expression in line #{line.line+1}: #{word.inspect}"
            end
          end
        else # Comments
          i = (line =~ /^\\[!#+-]\S/ ? 1 : 0)
          tokens << Token.new(:doc, line.line, line.char, line.text[i..-1])
        end
      end

      @tokens = tokens
    end

    def self.lex(name, source)
      Lexer.new(name, source).lex
    end
  end
end

