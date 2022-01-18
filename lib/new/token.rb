
module ShellOpts
  class Token
    # Kind of token. Can be :program, :option, :command, :arguments, :comment, :brief
    # (comment), or :blank (line). Each kind should have a corresponding Ast
    # class with the same name
    attr_reader :kind

    # Line number. Zero based
    attr_reader :line

    # Char number. Zero based. The lexer may adjust the char number (eg. for
    # blank lines)
    attr_accessor :char

    # Source of the token
    attr_reader :source

    def initialize(kind, line, char, source)
      @kind, @line, @char, @source = kind, line, char, source
    end

    forward_to :source, :to_s, :empty?

    def pos() "#{line+1}:#{char+1}" end

    def inspect() 
      "<#{self.class.to_s.sub(/.*::/, "")} #{pos} #{kind.inspect}" + 
          (kind != :program ? " #{source.inspect}" : "") +
      ">"
    end

    def dump
      puts "#{kind}@#{line+1}:#{char+1} #{source.inspect}"
    end
  end
end
