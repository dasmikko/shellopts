
module ShellOpts
  # Gives access to the ruby main object
  module Main
    CALLER_RE = /^.*:in `<main>'$/
    def self.main() TOPLEVEL_BINDING.eval("self") end
  end
end


