
require 'spec_helper.rb'
require 'shellopts/option_struct.rb'

include ShellOpts

describe ShellOpts::OptionStruct do
  def make_struct(usage, argv, aliases = {})
    make_idr(usage, argv).to_struct
  end

  describe ".new" do
    let(:struct) { make_struct("a b A! aa bb B!", "-a A --aa") }
    let(:struct_no_command) { make_struct("a b A! aa bb B!", "-a") }

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
      expect { struct.A! }.not_to raise_error
      expect { struct.B! }.not_to raise_error
      expect { struct.C! }.to raise_error NoMethodError

      expect(OptionStruct.class_of(struct.A!)).to be OptionStruct
      expect(struct.B!).to eq nil
    end

    it "defines a #subcommand method on the object" do
      expect { struct.subcommand }.not_to raise_error
      expect(struct.subcommand).to eq :A!
      expect(struct_no_command.subcommand).to eq nil
    end

    it "defines a #subcommand? method on the object" do
      expect { struct.subcommand? }.not_to raise_error
      expect(struct.subcommand?).to eq true
      expect(struct_no_command.subcommand?).to eq false
    end

    it "defines a #subcommand! method on the object" do
      expect { struct.subcommand! }.not_to raise_error
      expect(struct.subcommand!).to be struct.A!
      expect(struct_no_command.subcommand!).to eq nil
    end

    it "raises if option is a reserved word" do
      expect { make_struct("instance_eval", "") }.to raise_error ConversionError
      expect { make_struct("subcommand", "") }.to raise_error ConversionError
    end

    it "raises on name collisions on aliased keys"
    it "raises on name collisions between 'subcommand' and options"
    it "raises on name collisions between 'subcommand' and commands"
  end
end










