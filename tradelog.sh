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

export POSIXLY_CORRECT=yes
export LC_NUMERIC=en_US.UTF-8

print_help(){
    echo "Usage: tradelog [-h|--help]"
    echo "       tradelog [FILTER] [COMMAND] [LOG [LOG2 [...]]"
    echo ""
    echo "COMMANDS"
    echo "   list-tick     -prints list of occurring stock market symbols, so-called “tickers”"
    echo "   profit        -prints total profit from closed positions"
    echo "   pos           -prints values of currently held positions sorted downwardly based on value"
    echo "   last-price    -prints the last known value for each ticker"
    echo "   hist-ord      -prints a histogram of total number of transactions for each ticker"
    echo "   graph-pos     -prints a graph of values for held positions for each ticker"
    echo ""
    echo "FILTERS"
    echo "   -a DATETIME   -work only with records AFTER given date (without this date)"
    echo "                      (datetime needs to be entered in format YYYY-MM-DD HH:MM:SS)"
    echo "   -b DATETIME   -work only with records BEFORE given date (without this date)"
    echo "                      (datetime needs to be entered in format YYYY-MM-DD HH:MM:SS)"
    echo "   -t TICKER     -work only with records corresponding to the given ticker"
    echo "                 -in case of several uses of this filter at once, work with all entered tickers"
    echo "   -w WIDTH      -sets the width of printed graphs, i.e. sets the length of the longest row to given number"
    echo "                 -WIDTH has to be a whole number >= 1"
    echo "                 -several uses of this filter at once are not possible (script exits with Error)"
    echo ""
}