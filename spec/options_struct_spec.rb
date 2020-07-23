
require 'spec_helper.rb'
require 'shellopts/options_struct.rb'
require 'shellopts/options_hash.rb'

include ShellOpts

describe ShellOpts::OptionsStruct do
  def make_struct(opts, args, command_alias: :command)
    ShellOpts::ShellOpts.new(opts, args).to_struct(command_alias: command_alias)
  end

  describe ".new" do
    let(:struct) { make_struct("a b A! aa bb B!", %w(-a A --aa)) }

    it "returns a OptionsStruct for the given AST node" do
      expect(OptionsStruct.class_of(struct)).to be OptionsStruct
    end

    it "creates a reader method for each option" do
      expect { struct.a }.not_to raise_error
      expect { struct.b }.not_to raise_error
      expect { struct.c }.to raise_error NoMethodError
    end

    it "creates a query method for each option" do
      expect { struct.a? }.not_to raise_error
      expect { struct.b? }.not_to raise_error
      expect { struct.c? }.to raise_error NoMethodError

      expect(struct.a?).to eq true
      expect(struct.b?).to eq false
      expect { struct.c? }.to raise_error NoMethodError
    end

    it "creates a reader method for each command" do
      expect { struct.A! }.not_to raise_error
      expect { struct.B! }.not_to raise_error
      expect { struct.C! }.to raise_error NoMethodError

      expect(OptionsStruct.class_of(struct.A!)).to be OptionsStruct
      expect(struct.B!).to eq nil
    end

    it "creates a command method using :command_alias" do
      expect(struct.command).to eq :A!
      expect(make_struct("a A!", %w(-a A), command_alias: :cmd).cmd).to eq :A!
    end

    it "raises if option key is also a reserved word" do
      shellopts = ShellOpts::ShellOpts.new("instance_eval", %w(--instance_eval))
      expect { shellopts.to_struct }.to raise_error RepresentationError
    end

    it "raises if option key matched command alias" do
      shellopts = ShellOpts::ShellOpts.new("command", %w(--command))
      expect { shellopts.to_struct }.to raise_error RepresentationError
      shellopts = ShellOpts::ShellOpts.new("command A!", %w(--command A))
      expect { shellopts.to_struct(command_alias: :cmd) }.not_to raise_error
      expect(shellopts.to_struct(command_alias: :cmd).cmd).to eq :A!
    end
  end

  describe ".options_hash" do
    it "returns the underlying OptionsHash object" do
      struct = make_struct("a", %w(-a))
      expect(OptionsStruct.options_hash(struct)).to eq OptionsStruct.get_variable(struct, "@__options_hash__")

    end
  end

  describe ".class_of" do
    it "returns the class of the given object" do
      struct = make_struct("a", %w(-a))
      expect(OptionsStruct.class_of(struct)).to be OptionsStruct
    end
  end

  describe ".size" do
    it "forwards to OptionsHash#size" do
      struct = make_struct("a", %w(a))
      expect(OptionsStruct.options_hash(struct)).to receive(:size)
      OptionsStruct.size(struct)
    end
  end

  describe ".keys" do
    it "forwards to OptionsHash#key" do
      struct = make_struct("a", %w(a))
      expect(OptionsStruct.options_hash(struct)).to receive(:keys)
      OptionsStruct.keys(struct)
    end
  end

  describe ".name" do
    it "forwards to OptionsHash#name" do
      struct = make_struct("a", %w(a))
      expect(OptionsStruct.options_hash(struct)).to receive(:name)
      OptionsStruct.name(struct)
    end
  end

  describe ".node" do
    it "forwards to OptionsHash#node" do
      struct = make_struct("A!", %w(A))
      expect(OptionsStruct.options_hash(struct)).to receive(:node)
      OptionsStruct.node(struct)
    end
  end

  describe ".command" do
    it "forwards to OptionsHash#command" do
      struct = make_struct("A!", %w(A))
      expect(OptionsStruct.options_hash(struct)).to receive(:command)
      OptionsStruct.command(struct)
    end
  end
end










