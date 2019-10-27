
module ShellOpts
  # Use `include ShellOpts::Utils` to include ShellOpts utility methods in the
  # global namespace
  module Utils
    # Forwards to `ShellOpts.error`
    def error(*msgs)
      ::ShellOpts.error(*msgs)
    end

    # Forwards to `ShellOpts.fail`
    def fail(*msgs)
      ::ShellOpts.fail(*msgs)
    end
  end
end
