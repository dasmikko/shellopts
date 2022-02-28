module ShellOpts
  class Ansi
    def self.bold(bold = true, s) 
      bold && $stdout.tty? ? "[1m#{s}[0m" : s 
    end
  end
end

