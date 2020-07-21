
module ShellOpts
  class Messenger
    # Name of the program
    attr_accessor :program

    # Usage string. If defined it is printed with a 'Usage: #@program ' prefix
    attr_accessor :usage

    # Multiline description. If defined it will be printed instead of @usage
    attr_accessor :description

    def initialize(program, usage, description = nil)
      @program = program
      @usage = usage
      @description = description
    end

    # Print error message and usage string and exit with status 1
    def error(*msgs)
      $stderr.puts "#{program}: #{msgs.join}"
      $stderr.puts description || usage if description || usage
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

