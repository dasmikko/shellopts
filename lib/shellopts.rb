require "shellopts/version"

require 'shellopts/compiler.rb'
require 'shellopts/parser.rb'
require 'shellopts/generator.rb'
require 'shellopts/option_struct.rb'
require 'shellopts/messenger.rb'
require 'shellopts/main.rb'

# Name of program. Defined as the basename of the program file
PROGRAM = File.basename($PROGRAM_NAME)

# ShellOpts main Module
#
# This module contains methods to process command line options and arguments.
# ShellOpts keeps a reference in ShellOpts.shellopts to the result of the last
# command that was processed through its interface and use it as the implicit
# object of many of its methods. This matches the typical use case where only
# one command line is ever processed and makes it possible to create class
# methods that knows about the command like #error and #fail
#
# For example; the following process and convert a command line into a struct
# representation and also sets ShellOpts.shellopts object so that the #error
# method can print a relevant usage string:
#
#   USAGE = "a,all f,file=FILE -- ARG1 ARG2"
#   opts, args = ShellOpts.as_struct(USAGE, ARGV)
#   File.exist?(opts.file) or error "Can't find #{opts.file}"
#
# The command line is processed through one of the methods #process, #as_array,
# #as_hash, or #as_struct that returns a [data, args] tuple. The data type
# depends on the method: #process yields a Idr object that internally serves as
# the base for the #as_array and #as_hash and #as_struct that converts it into
# an Array, Hash, or ShellOpts::OptionStruct object. For example:
#
#   USAGE = "..."
#   ShellOpts.process(USAGE, ARGV)
#   program, args = ShellOpts.as_program(USAGE, ARGV)
#   array, args = ShellOpts.as_array(USAGE, ARGV)
#   hash, args = ShellOpts.as_hash(USAGE, ARGV)
#   struct, args = ShellOpts.as_struct(USAGE, ARGV)
#
# +args+ is a ShellOpts::Argv object containing the the remaning command line
# arguments. Argv is derived from Array
#
# ShellOpts can raise the exception CompilerError is there is an error in the
# USAGE string. If there is an error in the user supplied command line, #error
# is called instead and the program terminates with exit code 1. ShellOpts
# raises ConversionError is there is a name collision when converting to the
# hash or struct representations. Note that CompilerError and ConversionError
# are caused by misuse of the library and the problem should be corrected by
# the developer
#
# ShellOpts injects the constant PROGRAM into the global scope. It contains the 
# name of the program
#
# INCLUDING SHELLOPTS
# 
# ShellOpts can optionally be included in your shell application main file but
# it is not supposed to be included anywhere else
#
# Some behind the scenes magic happen if you include the ShellOpts module in your
# main exe file
#
module ShellOpts
  # Base class for ShellOpts exceptions
  class Error < RuntimeError; end

  # Raised when a syntax error is detected in the usage string
  class CompilerError < Error
    def initialize(start, message)
      super(message)
      set_backtrace(caller(start))
    end
  end

  # Raised when an error is detected in the command line
  class ParserError < Error; end

  # Raised when the command line error is caused by the user. It is raised by
  # the parser but can also be used by the application if the command line
  # fails a semantic check
  class UserError < ParserError; end

  # Raised when the error is caused by a failed assumption about the system. It
  # is not raised by the ShellOpts library as it only concerns itself with
  # command line syntax but can be used by the application to report a failure
  # through ShellOpts#fail method when the ShellOpts module is included
  class SystemFail < Error; end

  # Raised when an error is detected during conversion from the Idr to array,
  # hash, or struct
  class ConversionError < Error; end

  # Raised when an internal error is detected
  class InternalError < Error; end

  # The current compilation object. It is set by #process
  def self.shellopts() @shellopts end

  # Process command line, set current shellopts object, and return it.
  # Remaining arguments from the command line can be accessed through
  # +shellopts.args+
  def self.process(usage, argv, name: PROGRAM, message: nil)
    @shellopts.nil? or reset
    messenger = message && Messenger.new(name, message, format: :custom)
    @shellopts = ShellOpts.new(usage, argv, name: name, messenger: messenger)
  end

  # Process command line, set current shellopts object, and return a
  # [Idr::Program, argv] tuple. Automatically includes the ShellOpts module
  # if called from the main Ruby object (ie. your executable)
  def self.as_program(usage, argv, name: PROGRAM, message: nil) 
    Main.main.send(:include, ::ShellOpts) if caller.last =~ Main::CALLER_RE
    process(usage, argv, name: name, message: message)
    [shellopts.idr, shellopts.args]
  end

  # Process command line, set current shellopts object, and return a [array,
  # argv] tuple. Automatically includes the ShellOpts module if called from the
  # main Ruby object (ie. your executable)
  def self.as_array(usage, argv, name: PROGRAM, message: nil)
    Main.main.send(:include, ::ShellOpts) if caller.last =~ Main::CALLER_RE
    process(usage, argv, name: name, message: message)
    [shellopts.to_a, shellopts.args]
  end

  # Process command line, set current shellopts object, and return a [hash,
  # argv] tuple. Automatically includes the ShellOpts module if called from the
  # main Ruby object (ie. your executable)
  def self.as_hash(usage, argv, name: PROGRAM, message: nil, use: ShellOpts::DEFAULT_USE, aliases: {})
    Main.main.send(:include, ::ShellOpts) if caller.last =~ Main::CALLER_RE
    process(usage, argv, name: name, message: message)
    [shellopts.to_h(use: use, aliases: aliases), shellopts.args]
  end

  # Process command line, set current shellopts object, and return a [struct,
  # argv] tuple. Automatically includes the ShellOpts module if called from the
  # main Ruby object (ie. your executable)
  def self.as_struct(usage, argv, name: PROGRAM, message: nil, use: ShellOpts::DEFAULT_USE, aliases: {})
    Main.main.send(:include, ::ShellOpts) if caller.last =~ Main::CALLER_RE
    process(usage, argv, name: name, message: message)
    [shellopts.to_struct(use: use, aliases: aliases), shellopts.args]
  end

  # Process command line, set current shellopts object, and then iterate
  # options and commands as an array. Returns an enumerator to the array
  # representation of the current shellopts object if not given a block
  # argument. Automatically includes the ShellOpts module if called from the
  # main Ruby object (ie. your executable)
  def self.each(usage = nil, argv = nil, name: PROGRAM, message: nil, &block)
    Main.main.send(:include, ::ShellOpts) if caller.last =~ Main::CALLER_RE
    process(usage, argv, name: name, message: message)
    shellopts.each(&block)
  end

  # Print error message and usage string and exit with status 1. This method
  # should be called in response to user-errors (eg. specifying an illegal
  # option)
  def self.error(*msgs, exit: true)
    raise InternalError, "Oops" if shellopts.nil?
    shellopts.error(msgs, exit: exit)
  end

  # Print error message and exit with status 1. This method should not be
  # called in response to system errors (eg. disk full)
  def self.fail(*msgs)
    raise InternError, "Oops" if shellopts.nil?
    shellopts.fail(*msgs)
  end

  # Instance method version of ShellOpts.error. It is accessible when the
  # ShellOpts module is included
# def error(*msgs, exit: true) ShellOpts.error(*msgs, exit: exit) end

  # Instance method version of ShellOpts.fail. It is accessible when the
  # ShellOpts module is included
# def fail(*msgs) ShellOpts.fail(*msgs) end

  def self.included(base)
    # base.equal?(Object) is only true when included in main (we hope)
    if !@is_included_in_main && base.equal?(Object) 
      @is_included_in_main = true
      at_exit do
        case $!
          when ShellOpts::UserError
            ::ShellOpts.error($!.message, exit: false)
            exit!(1)
          when ShellOpts::SystemFail
            ::ShellOpts.fail($!.message)
            exit!(1)
        end
      end
    end
    super
  end


private
  # Reset state variables
  def self.reset()
    @shellopts = nil
  end

  @shellopts = nil
  @is_included_in_main = false
end

