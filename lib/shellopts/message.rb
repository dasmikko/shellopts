
module ShellOpts
  class Message
    attr_accessor :program
    attr_accessor :usage

    def initialize(program, usage)
      @program = program
      @usage = usage && "Usage: #{program} #{usage}"
    end

    # Print error message and usage string and exit with status 1
    def error(*msgs)
      $stderr.puts "#{program}: #{msgs.join}"
      $stderr.puts usage if usage
      exit 1
    end

    # Print error message and exit with status 1. It use the current ShellOpts
    # object if defined. This method should not be called in response to
    # user-errors but system errors (like disk full)
    def fail(*msgs)
      $stderr.puts "#{program}: #{msgs.join}"
      exit 1
    end
  end
end

