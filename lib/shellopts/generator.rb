
require 'shellopts/idr.rb'

module ShellOpts
  module Idr
    # Generates an Idr::Program from a ShellOpts object
    def self.generate(shellopts)
      Idr::Program.new(shellopts)
    end
  end
end




