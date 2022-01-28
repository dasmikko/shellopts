
require 'shellopts/constants.rb'

include ShellOpts::Constants



describe ShellOpts::Constants do
  describe "SHORT_OPTION_NAME_RE" do
    it "matches a short option" do
      expect(SHORT_OPTION_NAME_RE).to match("a")
      expect(SHORT_OPTION_NAME_RE).to match("A")
      expect(SHORT_OPTION_NAME_RE).to match("9")
      expect(SHORT_OPTION_NAME_RE).not_to match("_")
      expect(SHORT_OPTION_NAME_RE).not_to match("-")
      expect(SHORT_OPTION_NAME_RE).not_to match("[")
    end
  end
  describe "LONG_OPTION_NAME_RE" do
    it "matches a long option" do
      expect(LONG_OPTION_NAME_RE).not_to match("a")
      expect(LONG_OPTION_NAME_RE).to match("ab")
      expect(LONG_OPTION_NAME_RE).not_to match("Ab")
      expect(LONG_OPTION_NAME_RE).to match("aB")
      expect(LONG_OPTION_NAME_RE).to match("a-b")
      expect(LONG_OPTION_NAME_RE).to match("a_b")
    end
  end
  describe "OPTION_NAME_RE" do
    it "matches short or long options" do
      expect(SHORT_OPTION_NAME_RE).to match("a")
      expect(SHORT_OPTION_NAME_RE).to match("A")
      expect(SHORT_OPTION_NAME_RE).to match("9")
      expect(SHORT_OPTION_NAME_RE).not_to match("_")
      expect(SHORT_OPTION_NAME_RE).not_to match("-")
      expect(SHORT_OPTION_NAME_RE).not_to match("[")
      expect(LONG_OPTION_NAME_RE).to match("ab")
      expect(LONG_OPTION_NAME_RE).not_to match("Ab")
      expect(LONG_OPTION_NAME_RE).to match("aB")
      expect(LONG_OPTION_NAME_RE).to match("a-b")
      expect(LONG_OPTION_NAME_RE).to match("a_b")
    end
  end
  describe "INITIAL_SHORT_OPTION_RE" do
    it "matches an initial short option in an option group" do
      expect(INITIAL_SHORT_OPTION_RE).to match("-a")
      expect(INITIAL_SHORT_OPTION_RE).to match("+a")
      expect(INITIAL_SHORT_OPTION_RE).not_to match("-ab")
      expect(INITIAL_SHORT_OPTION_RE).not_to match("+ab")
      expect(INITIAL_SHORT_OPTION_RE).not_to match("--a")
      expect(INITIAL_SHORT_OPTION_RE).not_to match("++a")
    end
  end
  describe "INITIAL_LONG_OPTION_RE" do
    it "matches an initial long option in an option group" do
      expect(INITIAL_LONG_OPTION_RE).to match("--ab")
      expect(INITIAL_LONG_OPTION_RE).to match("++ab")
      expect(INITIAL_LONG_OPTION_RE).not_to match("-ab")
      expect(INITIAL_LONG_OPTION_RE).not_to match("+ab")
    end
  end
  describe "INITIAL_OPTION_SUB_RE" do
    it "matches the initial option in an option group" do
      expect(INITIAL_SHORT_OPTION_RE).to match("-a")
      expect(INITIAL_SHORT_OPTION_RE).to match("+a")
      expect(INITIAL_SHORT_OPTION_RE).not_to match("-ab")
      expect(INITIAL_SHORT_OPTION_RE).not_to match("+ab")
      expect(INITIAL_LONG_OPTION_RE).to match("--ab")
      expect(INITIAL_LONG_OPTION_RE).to match("++ab")
      expect(INITIAL_LONG_OPTION_RE).not_to match("--a")
      expect(INITIAL_LONG_OPTION_RE).not_to match("++a")
    end
  end

  describe "OPTION_GROUP_RE" do
    it "matches a group of options" do
      expect(OPTION_GROUP_RE).to match("-a")
      expect(OPTION_GROUP_RE).to match("--ab")
      expect(OPTION_GROUP_RE).to match("-a,ab")
      expect(OPTION_GROUP_RE).to match("--ab,a")
    end
  end

  describe "OPTION_ARG_RE" do
    it "matches an option argument" do
      expect(OPTION_ARG_RE).to match("A")
      expect(OPTION_ARG_RE).to match("A_-9")
      expect(COMMAND_IDENT_RE).not_to match("-A")
      expect(COMMAND_IDENT_RE).not_to match("9A")
      expect(COMMAND_IDENT_RE).not_to match("A_")
      expect(COMMAND_IDENT_RE).not_to match("A-")
    end
  end

  describe "OPTION_FLAGS_RE" do
    it "matches option flags" do
      expect(OPTION_FLAGS_RE).to match("=")
      expect(OPTION_FLAGS_RE).to match("=$")
      expect(OPTION_FLAGS_RE).to match("=#")
      expect(OPTION_FLAGS_RE).not_to match("=$#")
      expect(OPTION_FLAGS_RE).to match("=LBL")
      expect(OPTION_FLAGS_RE).to match("=$LBL")
      expect(OPTION_FLAGS_RE).to match("=#LBL")
      expect(OPTION_FLAGS_RE).to match("=?")
      expect(OPTION_FLAGS_RE).to match("=#?")
      expect(OPTION_FLAGS_RE).to match("=$?")
      expect(OPTION_FLAGS_RE).to match("=LBL?")
      expect(OPTION_FLAGS_RE).to match("=#LBL?")
      expect(OPTION_FLAGS_RE).to match("=$LBL?")
    end
  end

  describe "OPTION_RE" do
    it "matches an option declaration" do
      expect(OPTION_RE).to match("-a")
      expect(OPTION_RE).to match("+a")
      expect(OPTION_RE).to match("+a=")
      expect(OPTION_RE).to match("+a,bc=VALUE")
    end
    it "sets $1 to the option group" do
      OPTION_RE =~ "+a=$VALUE?"
      expect($1).to eq "+a"
      OPTION_RE =~ "+a,bc=$VALUE?"
      expect($1).to eq "+a,bc"
    end
    it "sets $2 to the argument flag" do
      OPTION_RE =~ "+a"
      expect($2).to eq nil
      OPTION_RE =~ "+a,bc=$VALUE?"
      expect($2).to eq "="
    end
    it "sets $3 to the type flag" do
      OPTION_RE =~ "+a,bc=VALUE?"
      expect($3).to eq nil
      OPTION_RE =~ "+a,bc=$VALUE?"
      expect($3).to eq "$"
    end
    it "sets $4 to the argument name" do
      OPTION_RE =~ "+a,bc=$?"
      expect($4).to eq nil
      OPTION_RE =~ "+a,bc=$VALUE?"
      expect($4).to eq "VALUE"
    end
    it "sets $5 to the optional flag" do
      OPTION_RE =~ "+a,bc=$VALUE"
      expect($5).to eq nil
      OPTION_RE =~ "+a,bc=$VALUE?"
      expect($5).to eq "?"
    end
  end

  describe "COMMAND_IDENT_RE" do
    it "matches a command identifier" do
      expect(COMMAND_IDENT_RE).to match("a")
      expect(COMMAND_IDENT_RE).to match("a_-9")
      expect(COMMAND_IDENT_RE).not_to match("_a")
      expect(COMMAND_IDENT_RE).not_to match("-a")
      expect(COMMAND_IDENT_RE).not_to match("9a")
      expect(COMMAND_IDENT_RE).not_to match("a_")
      expect(COMMAND_IDENT_RE).not_to match("a-")
    end
  end

  describe "COMMAND_RE" do
    it "matches a command" do
      expect(COMMAND_RE).not_to match("cmd")
      expect(COMMAND_RE).to match("cmd!")
    end
  end

  describe "COMMAND_PATH_RE" do
    it "matches a command path" do
      expect(COMMAND_PATH_RE).to match("cmd!")
      expect(COMMAND_PATH_RE).to match("cmd.cmd!")
    end
  end

  describe "ARGUMENT_RE" do
    it "matches an argument" do
      expect(ARGUMENT_RE).not_to match("arg")
      expect(ARGUMENT_RE).not_to match("A")
      expect(ARGUMENT_RE).to match("AR")
      expect(ARGUMENT_RE).to match("A-_9")
      expect(ARGUMENT_RE).not_to match("-A")
      expect(ARGUMENT_RE).not_to match("_A")
      expect(ARGUMENT_RE).not_to match("9A")
      expect(ARGUMENT_RE).not_to match("A-")
      expect(ARGUMENT_RE).not_to match("A_")
    end
  end

  describe "ARGUMENT_EXPR_RE" do
    it "matches an argument expression" do
      expect(ARGUMENT_EXPR_RE).not_to match("[abc")
      expect(ARGUMENT_EXPR_RE).to match("[ABC")
      expect(ARGUMENT_EXPR_RE).not_to match("[ABC anything")
      expect(ARGUMENT_EXPR_RE).to match("[ABC ANYTHING")
      expect(ARGUMENT_EXPR_RE).to match("[ABC [ANYTHING]]")
    end
  end
end























