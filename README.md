# Shellopts

`ShellOpts` is a simple Linux command line parsing libray that covers most modern use
cases incl. sub-commands. Options and commands are specified using a
getopt(1)-like string that is interpreted by the library to process the command
line

## Usage

The following program accepts the options -a or --all, --count, --file, and -v
or --verbose. It expects `--count` to have an optional integer argument,
`--file` to have a mandatory argument, and allows `-v` and `--verbose` to be
repeated:

```ruby
 
# Define options
USAGE = "a,all count=#? file= +v,verbose -- FILE..."

# Define default values
all = false
count = nil
file = nil
verbosity_level = 0

# Process command line and return remaining non-option arguments
args = ShellOpts.process(USAGE, ARGV) do |opt, arg|
  case opt
    when '-a', '--all';    all = true
    when '--count';        count = arg || 42
    when '--file';         file = arg # never nil
    when '-v, '--verbose'; verbosity_level += 1
  else
    fail "Internal Error: Unmatched option: '#{opt}'"
  end
end

# Process remaining command line arguments
args.each { |arg| ... }
```

Note that the `else` clause catches legal but unhandled options; it is not an
user error. It typically happens because of a missing or misspelled option name
in the `when` clauses

If there is an error in the command line options, the program will exit with
status 1 and print an error message and a short usage description on standard
error

## Processing

`ShellOpts.process` compiles a usage definition string into a grammar and use
that to parse the command line. If given a block, the block is called with a
name/value pair for each option or command and return a list of the remaining
non-option arguments

```ruby
args = ShellOpts.process(USAGE, ARGV) do |opt, arg|
  case opt
    when ...
  end
end
```

This calls the block for each option in the same order as on the command line
and return the remaining non-option args. It also sets up the `ShellOpts.error` and
`ShellOpts.fail` methods. Please note that you need to call `ShellOpts.reset`
if you want to process another command line

If `ShellOpts.process` is called without a block it returns a
`ShellOpts::ShellOpts` object. It can be used to process more than one command
line at a time and to inspect the grammar and AST

```ruby
shellopts = ShellOpts.process(USAGE, ARGV)  # Returns a ShellOpts::ShellOpts object
shellopts.each { |opt, val| ... }           # Access options
args = shellopts.args                       # Access remaining arguments
shellopts.error "Something went wrong"      # Emit an error message and exit
```

## Usage string

A usage string, typically named `USAGE`, is a list of option and command
definitions separated by whitespace. It can span multiple lines. A double
dash (`--`) marks the end of the definition, anything after that is not
interpreted but copied verbatim in error messages

The general [syntax](https://en.wikipedia.org/wiki/Extended_Backus%E2%80%93Naur_form) is

```EBNF
options { command options } [ "--" anything ]
```

## Options

An option is defined by a list of comma-separated names optionally prefixed by a
`+` and/or followed by a `=` and a set of flags. The syntax is

```EBNF
[ "+" ] name-list [ "=" [ "#" | "$" ] [ label ] [ "?" ] ]
```

#### Flags

There are the following flags:

|Flag|Effect|
|---|---|
|+|Repeated option (prefix)|
|=|Argument. Mandatory unless `?` is also used|
|#|Integer argument|
|$|Floating point argument|
|?|Optional argument|

#### Repeated options

Options are unique by default and the user will get an error if an option is
used more than once. You can tell the parser to allow several instances of the
same option by prefixing the option names with a `+`. A typical use case is to
let the user repeat a 'verbose' option to increase verbosity: `+v,verbose`
allows `-vvv` or `--verbose --verbose --verbose`. `ShellOpts::process` yields
an entry for each usage so should handle repeated options like this

```ruby
verbosity_level = 0

args = ShellOpts.process(USAGE, ARGV) do |opt, arg|
  case opt
    when '-v', '--verbose'; verbosity_level += 1
    # other options
  end
end
```

#### Option names

Option names are a comma-separated list of names. Names can consist of one or more
ASCII letters (a-zA-Z), digits, underscores ('\_') and dashes ('-').  A name
can't start with a dash, though

Names that are one character long are considered 'short options' and are
prefixed with a single dash on the command line (eg. '-a'). Names with two or
more characters are 'long options' and are used with two dashes (eg. '--all').
Note that short and long names handles arguments differently

Examples:
```
a               # -a
all             # --all
a,all           # -a or --all
r,R,recursive   # -r, -R, or --recursive
```

#### Option argument

An option that takes an an argument is declared with a `=` after the name list.
By default the type of an option is a `String` but a integer argument can be
specified by the `#` flag and a float argument by the `$` flag.  

You can label a option value that will be used in help texts and error
messages. A usage string like `file=FILE` will be displayed as `--file=FILE`
and `file=FILE?` like `--file[=FILE]`. If no label is given, `INT` will be used
for integer arguments, `FLOAT` for floating point, and else `ARG`

Arguments are mandatory by default but can be made optional by suffixing a `?`

## Commands

Sub-commands (like `git clone`) are defined by a name (or a dot-separated list
of names) followed by an exclamation mark. All options following a command are
local to that command. It is not possible to 'reset' this behaviour so global
options should always come before the first command. Nested commands are
specified using a dot-separated "path" to the nested sub-command

Examples
```
g,global clone! t,template=
g,global clone! t,template= clone.list! v,verbose
```

The last example could be called like `program -g clone list -v`. You may split
the usage string to improve readability:

```
g,global 
    clone! t,template= 
        clone.list! v,verbose
```

#### Command processing

Commands are treated like options but with a value that is an array of options (and 
sub-commands) to the command:

```ruby
USAGE = "a cmd! b c"

args = ShellOpts.process(USAGE, ARGV) { |opt,val|
  case opt
    when '-a'; # Handle -a
    when 'cmd'
      opt.each { |opt, val|
        case opt
          when '-b'; # Handle -b
          when '-c'; # Handle -c
        end
      }
  end
}
```

## Parsing

Parsing of the command line follows the UNIX traditions for short and long
options. Short options are one letter long and prefixed by a `-`. Short options
can be grouped so that `-abc` is the same as `-a -b -c`.  Long options are
prefixed with a `--` and can't be grouped

Mandatory arguments to short options can be separated by a whitespace (`-f
/path/to/file`) but optional arguments needs to come immediately after the
option: `-f/path/to/file`. Long options also allow a space separator for
mandatory arguments but use `=` to separate the option from optional arguments:
`--file=/path/to/file`

Examples
```
f=              # -farg or -f arg
f=?             # -farg

file=           # --file=arg or --file arg
file=?          # --file=arg
```

#### Error handling

If the command line is invalid, it's a user error and the program exits with
status 1 and prints an error message on STDERR 

If there is an error in the usage string, ShellOpts raises a
`ShellOpts::CompileError`. Note that this exception signals an error by the
application developer and shouldn't be catched. If there is an internal error
in the library, a ShellOpts::InternalError is raised and you should look for a
newer version of `ShellOpts` or file a bug-report

All ShellOpt exceptions derive from ShellOpt::Error

#### Error handling methods

ShellOpts provides two methods that can be used by the application to
generate error messages in the style of ShellOpts: `ShellOpts.error` and
`ShellOpts.fail`. Both write an error message on STDERR and terminates the
program with status 1. 

`error` is intended to respond to user errors (like giving a file name that
doesn't exist) and prints a short usage summary to remind the user:

```
<PROGRAM>: <MESSAGE>
Usage: <PROGRAM> <USAGE>
```
The usage string is a prettyfied version of the usage definition given to
ShellOpts

`fail` is used to report that something is wrong with the assumptions about the
system (eg. disk full) and omits the usage summary
```
<PROGRAM>: <MESSAGE>
```

The methods are defined as instance methods on `ShellOpts::ShellOpts` and as
class methods on `ShellOpts`. They can also be included in the global scope by
`include ShellOpts::Utils`

#### Usage string

The error handling methods prints a prettified version of the usage string
given to `ShellOpts.parse`. The usage string can be overridden by assigning to
`ShellOpts.usage`. A typical use case is when you want to split the usage
description over multiple lines:

```ruby

USAGE="long-and-complex-usage-string"
ShellOpts.usage = <<~EOD
  usage explanation
  split over
  multiple lines
EOD
```

Note that this only affects the module-level `ShellOpts.error` method and not
object-level `ShellOpts::ShellOpts#error` method. This is considered a bug and
will fixed at some point

## Example

The rm(1) command could be implemented like this
```ruby

require 'shellopts'

# Define options
USAGE = %{
  f,force i I interactive=WHEN? r,R,recusive d,dir 
  one-file-system no-preserve-root preserve-root 
  v,verbose help version
}

# Define defaults
force = false
prompt = false
prompt_once = false
interactive = false
interactive_when = nil
recursive = false
remove_empty_dirs = false
one_file_system = false
preserve_root = true
verbose = false

# Process command line
args = ShellOpts.process(USAGE, ARGV) { |opt, val|
  case opt
    when '-f', '--force';           force = true
    when '-i';                      prompt = true
    when '-I';                      prompt_once = true
    when '--interactive';           interactive = true; interactive_when = val
    when '-r', '-R', '--recursive'; recursive = true
    when '-d', '--dir';             remove_empty_dirs = true
    when '--one-file-system';       one_file_system = true
    when '--preserve-root';         preserve_root = true
    when '--no-preserve-root';      preserve_root = false
    when '--verbose';               verbose = true
    when '--help';                  print_help; exit
    when '--version';               puts VERSION; exit
  end
end

# Remaining arguments are files or directories
files = args
```


## See also

* [Command Line Options: How To Parse In Bash Using “getopt”](http://www.bahmanm.com/blogs/command-line-options-how-to-parse-in-bash-using-getopt)

## Installation

To install in your gem repository:

```
$ gem install shellopts
```

To add it as a dependency for an executable add this line to your application's
`Gemfile`. Use exact version match as ShellOpts is still in development:

```ruby
gem 'shellopts', 'x.y.z'
```

If you're developing a library, you should add the dependency to the `*.gemfile` instead:

```ruby
spec.add_dependency 'shellopts', 'x.y.z'
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake spec` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/[USERNAME]/shellopts.
