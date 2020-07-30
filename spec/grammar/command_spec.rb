require 'spec_helper.rb'

require 'shellopts'

module ShellOpts::Grammar
  describe Command do
    opts = [Option.new(%w(-a), %w(--all), {}), Option.new(%w(-b), [], {})]

    describe "#initialize" do
      it "attaches to parent" do
        root = Command.new(nil, "root", [])
        cmd = Command.new(root, "cmd", [])
        expect(cmd.parent).to eq root
      end
      it "initialize Node#key" do
        cmd = Command.new(nil, "cmd", [])
        expect(cmd.key).to eq :cmd!
      end
    end

    describe "#key" do
      it "includes the suffixed exclmation point" do
        grammar = ShellOpts::Grammar.compile("program", "cmd!")
        expect(grammar.subcommands["cmd"].key).to eq :cmd!
      end
    end

    describe "#options" do
      it "is a hash from option names to Option objects" do
        cmd = Command.new(nil, "cmd", opts)
        expect(cmd.options["-a"]).to eq opts.first
        expect(cmd.options["--all"]).to eq opts.first
        expect(cmd.options["-b"]).to eq opts.last
      end
    end

    describe "#subcommands" do
      it "is a hash from subcommand name to Command object" do
        cmd = Command.new(nil, "cmd", [])
        sub1 = Command.new(cmd, "sub1", [])
        sub2 = Command.new(cmd, "sub2", [])
        expect(cmd.subcommands["sub1"]).to be sub1
        expect(cmd.subcommands["sub2"]).to be sub2
      end
    end

    describe "#option_list" do
      it "is a list of options in declaration order" do
        cmd = Command.new(nil, "cmd", opts)
        expect(cmd.option_list).to eq opts
      end
    end

    describe "#subcommand_list" do
      it "is a list of subcommands in declaration order" do
        cmd = Command.new(nil, "cmd", [])
        sub1 = Command.new(cmd, "sub1", [])
        sub2 = Command.new(cmd, "sub2", [])
        expect(cmd.subcommand_list).to eq [sub1, sub2]
      end
    end
  end
end
