
# MAN pages
#
# NAME
#   #{$PROGRAM_NAME} - #{BRIEF || spec.summary}
#
# USAGE
#   #{USAGE || shellopts.usage}
#
# DESCRIPTION
#   #{DESCRIPTION || spec.description}
#
# OPTIONS
#   #{OPTIONS || shellopts.options}
#
# COMMANDS
#   #{COMMANDS || shellopts.commands}
#   

# Help output
#
# #{BRIEF}
#
# Usage: #{USAGE || shellopts.usage}
#
# Options:
#   #{OPTIONS_IN_SHORT_FORMAT | shellopts.options_in_short_format}
#
# Commands
#   #{COMMANDS_IN_SHORT_FORMMAT | shellopts.commands_in_short_format}
#

h = %(
  -a,all # Include all files
  -f=FILE # Use this file
)

# Default options
#   <defaults>
#     Can be processed by ShellOpts.process_defaults
#     ShellOpts.make(SPEC, ARGV, defaults: true)
#
# Options
#   -a,b,long
#   --long
#   -a=FILE
#   -e,env,environment=ENVIRONMENT:p,d,t,prod,dev,test,production,development
#   -i=# # Integer
#   -o=optional?
#   --verbose* # Repeated
#   -a=V* # Repeated with argument
#   -a=V?* # Repeated, optionally with argument
#
# Arguments
#   Arguments has to be on one line (per ++ or --)
#
#   ++ ARG...
#     Subcommand arguments
#   -- ARG...
#     Command arguments. Multiple -- definitions are allowed
#
#   [ARG]
#     Optional argument
#   ARG
#     Mandatory argument
#   ARG...
#     Repeated argument. At least one argument is mandatory
#   [ARG...]
#     Optionally repeated argument
#
# SPECIAL ALTERNATE VALUES OR ARGUMENTS
#   FILE:EFILE
#     Existing file. "FILE" will be used as name of the value
#   PATH:EPATH
#     Existing file or directory. "PATH" will be used as the name of the value
#   DIRECTORY:EDIR
#     Existing directory. "DIRECTORY" will be used as name of the value
#
# SPEC = %(
#   # Common options
#   -f,file=FILE
#   -- ARG ARG
#
#   # More options
#   -m,mode=MODE
#   -- ARG ARG ARG
# )
#
# How to make
#   cp [OPTION]... [-T] SOURCE DEST
#   cp [OPTION]... SOURCE... DIRECTORY
#   cp [OPTION]... -t DIRECTORY SOURCE...
#
#   USAGE = %(
#     cp [OPTION]... [-T] SOURCE DEST
#     cp [OPTION]... SOURCE... DIRECTORY
#     cp [OPTION]... -t DIRECTORY SOURCE...
#   )
#
#   SPEC = %(
#     -r,recursive
#  
#     -T,no-target-directory
#  
#     -t,target_directory=DIRECTORY:EDIR
#   )
#   



