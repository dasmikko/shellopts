
module ShellOpts
  class CompileError < StandardError; end

  class ShellOptsError < RuntimeError; end

  class Error < ShellOptsError
    attr_reader :subject

    def initialize(subject = nil) 
      super()
      @subject = subject
    end
  end

  class Fail < ShellOptsError; end
end

class NotYet < NotImplementedError; end
class NotThis < ScriptError; end # Pure virtual method called
class NotHere < ScriptError; end # Unexpected case
