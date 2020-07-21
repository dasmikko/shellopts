require 'spec_helper.rb'

require 'shellopts/message'

include ShellOpts

describe ShellOpts::Message do
  subject { Message.new("cmd", "-a -b") }

  describe "#error" do
    it "terminates the program with status 1" do
      allow(STDERR).to receive(:puts) # Silence #error
      expect { subject.error("Error message") }.to raise_error SystemExit
    end

    it "writes the message and usage on stderr" do
      expected = "cmd: Error message\nUsage: cmd -a -b\n"
      expect {
        begin
          subject.error("Error message")
        rescue SystemExit
        end
      }.to output(expected).to_stderr
    end

    context "if #usage has been assigned to" do
      it "doesn't prefix the usage string with 'Usage: \#{program} '" do
        subject.usage = "multiline\ndescription"
        expected = "cmd: Error message\nmultiline\ndescription\n"
        expect {
          begin
            subject.error("Error message")
          rescue SystemExit
          end
        }.to output(expected).to_stderr

      end
    end
  end

  describe "#fail" do
    it "terminates the program with status 1" do
      allow(STDERR).to receive(:puts) # Silence #error
      expect { subject.fail("Error message") }.to raise_error SystemExit
    end
    it "writes the message on stderr" do
      expected = "cmd: Error message\n"
      expect {
        begin
          subject.fail("Error message")
        rescue SystemExit
        end
      }.to output(expected).to_stderr
    end
  end
end

