
module ShellOpts
  class Token
    # Each kind should have a corresponding Grammar class with the same name
    KINDS = [:program, :option, :command, :spec, :argument, :usage, :usage_string, :brief, :text, :blank]

    # Kind of token
    attr_reader :kind

    # Line number. Zero based
    attr_reader :line

    # Char number. Zero based. The lexer may adjust the char number (eg. for
    # blank lines)
    attr_accessor :char

    # Source of the token
    attr_reader :source

    def initialize(kind, line, char, source)
      constrain kind, :program, *KINDS
      @kind, @line, @char, @source = kind, line, char, source
    end

    forward_to :source, :to_s, :empty?

    def pos() "#{line+1}:#{char+1}" end

    def to_s() source end

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
