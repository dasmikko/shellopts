require 'spec_helper.rb'

require 'shellopts/messenger'

include ShellOpts

describe ShellOpts::Messenger do
  let(:message) { Messenger.new("cmd", "-a -b") }

  describe "#name=" do
    it "strips prefixed and suffixed whitespaces" do
      message.name = " cmd "
      expect(message.name).to eq "cmd"
    end
  end

  describe "#usage=" do
    it "strips suffixed whitespaces" do
      message.usage = " usage "
      expect(message.usage).to eq " usage"
    end
    it "sets #format to :custom" do
      expect(message.format).to eq :default
      message.usage = "usage"
      expect(message.format).to eq :custom
    end
  end

  describe "#error" do
    def expect_error(message)
      expect {
        begin
          message.error "Error message"
        rescue SystemExit
        end
      }
    end

    it "terminates the program with status 1" do
      allow(STDERR).to receive(:print) # Silence #error
      expect { message.error("Error message") }.to raise_error SystemExit
    end

    it "writes the message on stderr" do
      expected = "cmd: Error message\nUsage: cmd -a -b\n"
      expect_error(message).to output(expected).to_stderr
    end

    it "doesn't exit if exit: is false" do
      allow(STDERR).to receive(:print) # Silence #error
      expect { message.error("Error message", exit: false) }.not_to raise_error
    end

    context "when usage is nil" do
      it "doesn't print the usage" do
        expected = "cmd: Error message\n"
        message.usage = nil
        message.format = :default
        expect_error(message).to output(expected).to_stderr
        message.format = :custom
        expect_error(message).to output(expected).to_stderr
      end
    end

    context "when format is :custom'" do
      it "doesn't format the usage string" do
        expected = "cmd: Error message\nmultiline\ndescription\n"
        message = Messenger.new("cmd", "multiline\ndescription")
        message.format = :custom
        expect_error(message).to output(expected).to_stderr
      end
    end
  end

  describe "#fail" do
    def expect_fail(message)
      expect {
        begin
          message.fail "Error message"
        rescue SystemExit
        end
      }
    end

    it "terminates the program with status 1" do
      allow(STDERR).to receive(:puts) # Silence #error
      expect { message.fail("Error message") }.to raise_error SystemExit
    end

    it "writes the message on stderr" do
      expected = "cmd: Error message\n"
      expect_fail(message).to output(expected).to_stderr
    end
  end
end

