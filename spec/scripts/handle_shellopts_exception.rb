#!/usr/bin/env ruby

$LOAD_PATH << 'lib/'

require 'shellopts.rb'

include ShellOpts

opts, args = ::ShellOpts.as_struct("a", %w(-a -b))

