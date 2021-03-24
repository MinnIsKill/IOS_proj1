#!/bin/sh

#     LORD GIVE ME THE MENTAL CAPACITY TO REMEMBER THESE, but in the meantime, this cheatsheet should suffice.
# GitHub push flow:   $ git add .
#                     $ git commit -m "message"
#                     $ git push --set-upstream origin main   (where 'main' is name of branch to commit to)
#
# !!!(Forces local file overwrite)!!!
# GitHub pull flow:   $ git fetch origin main
#                     $ git reset --hard origin/main
#
# VSCode Keybind-sheet:  CTRL+SHIFT+B -> BUILD
#                        F5 -> DEBUG

# !!!
# pro jeden den mi to myslim stacilo, video jsem skoncil v cca 39:30, pushuju a jdu na prednasky...

export POSIXLY_CORRECT=yes
export LC_NUMERIC=en_US.UTF-8

print_help(){
    echo "Usage: tradelog [-h|--help]"
    echo "       tradelog [FILTER] [COMMAND] [LOG [LOG2 [...]]"
    echo ""
    echo "COMMANDS (only one can be used with each call)"
    echo ""
    echo "   list-tick     -prints list of occurring stock market symbols, so-called “tickers”"
    echo "   profit        -prints total profit from closed positions"
    echo "   pos           -prints values of currently held positions sorted downwardly based on value"
    echo "   last-price    -prints the last known value for each ticker"
    echo "   hist-ord      -prints a histogram of total number of transactions for each ticker"
    echo "   graph-pos     -prints a graph of values for held positions for each ticker"
    echo ""
    echo "FILTERS (more than one can be used with each call)"
    echo ""
    echo "   -a DATETIME   -work only with records AFTER given date (without this date)"
    echo "                      (datetime has to be entered in format YYYY-MM-DD HH:MM:SS)"
    echo "   -b DATETIME   -work only with records BEFORE given date (without this date)"
    echo "                      (datetime has to be entered in format YYYY-MM-DD HH:MM:SS)"
    echo "   -t TICKER     -work only with records corresponding to the given ticker"
    echo "                 -in case of several uses of this filter at once, work with all entered tickers"
    echo "   -w WIDTH      -sets the width of printed graphs, i.e. sets the length of the longest row to given number"
    echo "                 -WIDTH has to be a whole number >= 1"
    echo "                 -several uses of this filter at once are not possible (script exits with Error)"
    echo ""
}

a_DATETIME="0000-00-00 00:00:00"    # initialize to a value where everything will be after this date
                                    # (alternatively, an empty string would suffice)
b_DATETIME="9999-99-99 24:00:00"    # initialize to a value where everything will be before this date

TICKERS=""
COMMAND=""                          # variable for loaded command (CAN ALWAYS BE ONLY ONE)
LOG_FILEZ=""
GZ_LOG_FILES=""

while ["$#" -gt 0]; do      # while there are arguments to be read from input
    case "$1" in            # $1 means parameter #1
    list-tick | profit | pos | last-price | hist-ord | graph-pos)
        #if (COMMAND != NULL) --> ERROR (two commands were input)
        COMMAND="$1"
        shift               # throws away the argument we just loaded, and moves all the other arguments one to the left
        ;;                  # second arguments will now be first, third will be second, etc.
    -h | --help)
        print_help
        exit 0
        ;;
    -w)
        WIDTH="$2"
        shift
        shift
        ;;
    #-t)
        TICKERS="$1|$TICKERS"
    #-a)
        #a_DATETIME="$2 $3"
        #shift
        #shift
        #shift
        #;;
    #-b)
        #b_DATETIME="$2 $3"
        #shift
        #shift
        #shift
        #;;
    esac


#TADY BUDU DOPLNOVAT FUNKCE PRO KAZDY COMMAND
    if [COMMAND==""]; then
        eval "$READ_FILTERED | awk "
    fi





done

GZ_READ_INPUT="gzip -d -c $GZIP | cat $LOG_FILES - | sort"
READ_INPUT="cat $LOG_FILES - | sort"
NO_INPUT="cat"

NOTICKS_FILTER="cat"
TICKS_FILTER="grep '^.*;\($TICKERS\)'"

READ_FILTERED="eval $READ_INPUT | awk -F ';' 'if (\$1 > $a_DATETIME &&) {print \$0}' | eval $TICK_FILTER"    #';' is separator(delimiter)