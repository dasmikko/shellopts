require 'spec_helper.rb'

require 'shellopts'

module ShellOpts::Grammar
  describe Program do
    describe "#argv" do
      it "is an array of non-option litteral arguments" do
        grammar = ShellOpts::Grammar.compile("program", "a -- INPUT OUTPUT")
        expect(grammar.args).to eq %w(INPUT OUTPUT)
      end
    end

    describe '#usage' do
      def usage(s) ShellOpts::Grammar.compile("program", s).usage end

      it 'prints the short name by default' do
        expect(usage("a,aa b,bb")).to eq "-a -b"
      end
      it 'falls back to the long name if no short name' do
        expect(usage("a,aa bb")).to eq "-a --bb"
      end
      it 'prints the argument name by default' do
        expect(usage("f=FILE")).to eq "-f=FILE"
        expect(usage("f,file=FILE")).to eq "-f=FILE"
        expect(usage("file=FILE")).to eq "--file=FILE"
      end
      it 'handles non-flag characters in option names' do
        expect(usage("map=NAME=VALUE")).to eq "--map=NAME=VALUE"
      end
      it 'uses a default name if no explicit argument name' do
        expect(usage("i=# f=$ s=")).to eq "-i=INT -f=FLOAT -s=ARG"
      end
      it 'marks optional arguments' do
        expect(usage("c=COLOR?")).to eq "-c[=COLOR]"
      end
      it "handles commands" do
        expect(usage("a cmd! b c")).to eq "-a cmd -b -c"
        expect(usage("a cmd1! b c cmd1.cmd2! d")).to eq "-a cmd1 -b -c cmd2 -d"
        expect(usage("a cmd1! b c cmd1.cmd2! d cmd2! e")).to eq "-a cmd1 -b -c cmd2 -d cmd2 -e"
      end
      it "copies everthing after '--'" do
        expect(usage("a b -- FILE")).to eq "-a -b FILE"
        expect(usage("-- FILE")).to eq "FILE"
      end
    end
  end
end
