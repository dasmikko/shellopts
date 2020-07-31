#!/usr/bin/env ruby

$LOAD_PATH << 'lib/'

require 'shellopts.rb'
require 'shellopts/main.rb'

PRG = File.basename($0)
USG = ""

def error(*args)
  $stderr.puts "#{PRG}: #{args.join}"
  $stderr.puts "#{PRG}: #{USG}"
  exit 1
end

!Object.included_modules.include?(ShellOpts) or error("ShellOpts is already included")

ARGV.size == 1 or error "Illegal number of arguments"
SRC = ARGV.first

ShellOpts.instance_eval(SRC)

if ShellOpts::Main.main.class.included_modules.include?(ShellOpts)
  puts "ShellOpts is included"
else
  puts "ShellOpts is not included"
end
