#!/usr/bin/env ruby

$LOAD_PATH << 'lib/'

require 'shellopts.rb'

include ShellOpts

opts, args = ShellOpts.as_struct("a", %w(-a))

ARGV.size == 1 or raise "Illegal number of arguments"
klass_name = ARGV.first
klass = self.instance_eval(klass_name)

raise klass, "#{klass_name} handled"

#opts, args = ShellOpts.as_struct("a C!", [])
#opts.subcommand!
