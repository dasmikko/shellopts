
include ShellOpts::Grammar

describe ShellOpts do
  describe Command do
    def prg() Program.new("rspec") end
    def cmd() Command.new("path.to.command!") end

    describe "#name" do
      it "is the name of the command" do
        expect(cmd.name).to eq "command"
      end
      it "is nil for the Program object" do
        expect(prg.name).to eq "rspec"
      end
    end
    describe "#ident" do
      it "is the identifier of the command" do
        expect(cmd.ident).to eq :command
      end
      it "replaces '-' in names with '_'" do
        expect(Command.new("first-last").ident).to eq :first_last
      end
      it "is nil for the Program object" do
        expect(prg.ident).to eq nil
      end
    end
    describe "#path" do
      it "is the path of the command" do
        expect(cmd.path).to eq "path.to.command"
      end
      it "is the empty string for the Program object" do
        expect(prg.path).to eq ""
      end
    end
    describe "#parent_path" do
      it "is the path to the parent command" do
        expect(cmd.parent_path).to eq "path.to"
      end
      it "is nil when the parent is the program" do
        expect(prg.parent_path).to eq nil
      end
    end
  end
end
