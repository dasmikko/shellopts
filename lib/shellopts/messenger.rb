
module ShellOpts
  # Service object for output of messages
  #
  # Messages are using the common command line formats
  #
  class Messenger
    # Name of the program. When assigning to +name+ prefixed and suffixed
    # whitespaces are removed
    attr_accessor :name

    # :nodoc:
    def name=(name) @name = name.strip end
    # :nodoc:

    # Usage string. If not nil the usage string is printed by #error. When
    # assigning to +usage+ suffixed whitespaces are removed and the format
    # automatically set to +:custom+
    attr_accessor :usage

    # :nodoc:
    def usage=(usage) 
      @format = :custom
      @usage = usage&.rstrip
    end
    # :nodoc:

    # Format of the usage string: +:default+ prefixes the +usage+ with 'Usage:
    # #{name} ' before printing. +:custom+ prints +usage+ as is
    attr_accessor :format

    # Initialize a Messenger object. +name+ is the name of the name and +usage+
    # is a short description of the options (eg. '-a -b') or a longer multiline
    # explanation. The +:format+ option selects bewtween the two: +short+ (the
    # default) or :long. Note that 
    #
    def initialize(name, usage, format: :default)
      @name = name
      @usage = usage
      @format = format
    end

    # Print error message and usage string and exit with status 1. Output is
    # using the following format
    #
    #   <name name>: <message>
    #   Usage: <name name> <options and arguments>
    #
    def error(*msgs, exit: true)
      $stderr.print "#{name}: #{msgs.join}\n"
      if usage
        $stderr.print "Usage: #{name} " if format == :default
        $stderr.print "#{usage}\n"
      end
      Kernel.exit(1) if exit
    end

    # Print error message and exit with status 1. It use the current ShellOpts
    # object if defined. This method should not be called in response to
    # user-errors but system errors (like disk full). Output is using the
    # following format:
    #
    #   <name name>: <message>
    #
    def fail(*msgs)
      $stderr.puts "#{name}: #{msgs.join}"
      exit 1
    end
  end
end

