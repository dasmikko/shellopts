require 'spec_helper.rb'

require 'shellopts/generator.rb'

include ShellOpts

describe ShellOpts::Idr do


  describe ".generate" do
    it "generates an Idr::Program from an Ast::Program" do
      name = PROGRAM
      grammar = Grammar.compile(name, "a")
      messenger = Messenger.new(name, grammar.usage)
      ast = Ast.parse(grammar, %w(-a))
      idr = Idr.generate(ast, nil)
      expect(idr).to be_a Idr::Program
    end
  end
end
