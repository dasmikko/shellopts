require 'spec_helper.rb'
require 'shellopts.rb'

module ShellOpts::Ast
  describe Program do
    describe "#arguments" do
      it "is initially nil" do
        grammar = ShellOpts::Grammar.compile("program", "a")
        program = Program.new(grammar)
        expect(program.arguments).to eq nil
      end
      it "is assigned by the parser" do
        grammar = ShellOpts::Grammar.compile("program", "a")
        program = ShellOpts::Ast.parse(grammar, [])
        expect(program.arguments).to be_an Array
      end
      it "contains the remaining command line arguments" do
        grammar = ShellOpts::Grammar.compile("program", "a")
        program = ShellOpts::Ast.parse(grammar, %w(arg1 arg2))
        expect(program.arguments).to eq %w(arg1 arg2)
      end
    end
    it "is a boring sub-class of Command" do
      expect(Program < Command).to be true
    end
  end
end



