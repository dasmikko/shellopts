
module ShellOpts
  class Analyzer
    include Grammar
    using Stack

    attr_reader :grammar

    def initialize(grammar)
      @grammar = grammar
      @objekts = [] # Stack
    end


    def analyze()
      @grammar.link
      puts
      @grammar.dump_command

#     @grammar.traverse(Grammar::Option) { |opt|
#       puts opt.token.source
#     }
#     @grammar.traverse(Grammar::Command) { |cmd|
#       puts cmd.name
#     }
    end

    def Analyzer.analyze(source) self.new(source).analyze end

  protected
    def link(node)
      @objekts.push node
      node.children.each { |node| link(node) }
      @objekts.pop node
    end
  end
end
