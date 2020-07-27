
require 'shellopts/idr.rb'

module ShellOpts
  module Idr
    # Generates an Idr::Program from an Ast::Program object
    def self.generate(ast, messenger)
      Idr::Program.new(ast, messenger)
    end
  end
end




