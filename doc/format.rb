    # One-line format in prioritized order
    # ------------------------------------
    #
    #   cmd -a -b -c [CMD|CMD] ARGS
    #   cmd -a -b -c <command> ARGS
    #   cmd <options> [CMD|CMD] <ARGS>
    #   cmd <options> <command> <ARGS>
    #
    # Multiline format
    # ----------------
    #
    #   cmd -a -b -c [CMD|CMD] ARGS   # <- only if no subcommand options or arguments
    #
    #   cmd -a -b -c <command> ARGS
    #       subcmd -e -f -g ARGS
    #       subcmd -h -i -j ARGS
    #
    #   cmd -a -b -c 
    #       -d -e
    #       [CMD|CMD] ARGS
    #
    #   cmd -a -b -c 
    #       -d -e
    #       <command> ARGS
    #
    # Brief format
    # ------------
    #
    #   Name - Brief
    #
    #   Usage: 
    #     cmd -a -b -c [CMD|CMD] ARGS
    #
    #   Options:
    #     -a                    Brief
    #     -b                    Brief
    #     -c                    Brief
    #
    #   Commands:
    #     CMD --opts ARGS       Brief
    #     CMD --opts ARGS_THAT_TAKES_UP_A_LOT_OF_SPACE       
    #                           Brief
    #
    # Brief Command
    #     CMD --opts ARGS       Brief
    #     CMD --opts ARGS_THAT_TAKES_UP_A_LOT_OF_SPACE       
    #                           Brief
    #
    # Brief Option
    #   -a            Brief
    #   -b=a_very_long_option
    #                 Brief
    #    
    #
    # Doc format
    # ----------
    #
    #   Name
    #     Name - Brief
    #
    #   Usage:
    #     cmd -a -b -c [CMD|CMD] ARGS
    #
    #   Description
    #     Descr
    #
    #   Options:
    #     -a
    #       Descr
    #     -b
    #       Descr
    #     -c
    #       Descr
    #
    #   Commands:
    #     CMD -d -e -f ARGS
    #       Descr
    #
    #       -d
    #         Descr
    #       -e
    #         Descr
    #       -f 
    #         Descr
    #
    #     CMD -g -h -i ARGS
    #       Descr
    #
    #       -g
    #         Descr
    #       -h
    #         Descr
    #       -i 
    #         Descr
    #
