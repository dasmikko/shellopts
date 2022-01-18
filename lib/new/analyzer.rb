
module ShellOpts
  class Analyzer
    attr_reader :grammar

    def initialize(grammar)
      @grammar = grammar
    end



    def analyze() 
      @grammar.traverse(Grammar::Option) { |opt|
        puts opt.token.source
      }
      @grammar.traverse(Grammar::Command) { |cmd|
        puts cmd.name
      }
    end

    def Analyzer.analyze(source) self.new(source).analyze end
  end
end
