
require 'spec_helper.rb'
require 'shellopts/option_struct.rb'

include ShellOpts

describe ShellOpts::OptionStruct do
  def make_struct(usage, argv, aliases = {})
    make_idr(usage, argv).to_struct(aliases: aliases)
  end

  let(:struct) { make_struct("a b A! aa bb B!", "-a A --aa") }
  let(:struct_no_command) { make_struct("a b A! aa bb B!", "-a") }

  describe ".new" do
    it "creates an OptionStruct object" do
      expect(OptionStruct.class_of(struct)).to be OptionStruct
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
      expect { struct.A }.not_to raise_error
      expect { struct.B }.not_to raise_error
      expect { struct.C }.to raise_error NoMethodError

      expect(OptionStruct.class_of(struct.A)).to be OptionStruct
      expect(struct.B).to eq nil
    end

    it "defines a #subcommand method on the object" do
      expect { struct.subcommand }.not_to raise_error
    end

    it "defines a #subcommand? method on the object" do
      expect { struct.subcommand? }.not_to raise_error
      expect(struct.subcommand?).to eq true
    end

    it "defines a #subcommand! method on the object" do
      expect { struct.subcommand! }.not_to raise_error
    end

    it "raises if option is a reserved word" do
      expect { make_struct("instance_eval", "") }.to raise_error ConversionError
      expect { make_struct("subcommand", "") }.to raise_error ConversionError
    end

    it "applies aliases"
    it "use the naming convention given by :key_type"
    it "raises on name collisions on aliased keys"
    it "raises on name collisions between 'subcommand' and options"
    it "raises on name collisions between 'subcommand' and commands"
  end

  describe "#subcommand" do
    it "returns the key of the subcommand" do
      expect(struct.subcommand).to eq :A
    end
    it "returns nil if no subcommand was given" do
      expect(struct_no_command.subcommand).to eq nil  
    end
  end

  describe "#subcommand?" do
    it "returns true if the a subcommand was given" do
      expect(struct.subcommand?).to eq true
      expect(struct_no_command.subcommand?).to eq false
    end
  end

  describe "#subcommand!" do
    it "returns the key of the subcommand" do
      expect(struct.subcommand!).to eq :A
    end

    it "raises a UserError if no subcommand" do
      expect { struct_no_command.subcommand! }.to raise_error ::ShellOpts::UserError
    end

    it "forwards the messages if specified" do
      raised = false
      begin
        struct_no_command.subcommand!("Error message")
      rescue UserError => ex
        raised = true
        expect(ex.message).to eq "Error message"
      end
      expect(raised).to be true
    end
  end
end










