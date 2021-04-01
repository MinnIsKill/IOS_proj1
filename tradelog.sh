#!/bin/bash

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

#Pokud skript nedostane ani filtr ani příkaz, opisuje záznamy na standardní výstup.
#Skript umí zpracovat i záznamy komprimované pomocí nástroje gzip (v případě, že název souboru končí .gz).
#V případě, že skript na příkazové řádce nedostane soubory se záznamy (LOG, LOG2 …), očekává záznamy na standardním vstupu.
#Pokud má skript vypsat seznam, každá položka je vypsána na jeden řádek a pouze jednou. Není-li uvedeno jinak, je pořadí 
#  řádků dáno abecedně dle tickerů. Položky se nesmí opakovat.
#Grafy jsou vykresleny pomocí ASCII a jsou otočené doprava. Každý řádek histogramu udává ticker. Kladná hodnota či četnost 
#  jsou vyobrazeny posloupností znaku mřížky #, záporná hodnota (u graph-pos) je vyobrazena posloupností znaku vykřičníku !.

#Skript žádný soubor nemodifikuje. Skript nepoužívá dočasné soubory.
#Můžete předpokládat, že záznamy jsou ve vstupních souborech uvedeny chronologicky a je-li na vstupu více souborů, jejich pořadí je také chronologické.

#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#Pořadí argumentů stačí uvažovat takové, že nejřív budou všechny přepínače, pak (volitelně) příkaz a nakonec 
#seznam vstupních souborů (lze tedy použít getopts). Podpora argumentů v libovolném pořadí je nepovinné rozšíření, 
#jehož implementace může kompenzovat případnou ztrátu bodů v jiné časti projektu.
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

#TODO: solve zipped logs problem
#TODO: figure out multiple logs problem

export POSIXLY_CORRECT=yes
export LC_NUMERIC=en_US.UTF-8

print_help() {
    echo ""
    echo "Usage: tradelog [-h|--help]"
    echo "       tradelog [FILTER] [COMMAND] [LOG [LOG2 [...]]"
    echo ""
    echo "COMMANDS (only one can be used with each call)"
    echo ""
    echo "   list-tick     -prints list of occurring stock market symbols, so-called \"tickers\""
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
w_flag=0
help_flag=0

TICKERS=""
COMMAND=""                          # variable for loaded command (CAN ALWAYS BE ONLY ONE)
LOG_FILES=""
GZ_LOG_FILES=""

#=====================================================================
#                           FILTERS PARSING
#=====================================================================
for param in "$@"; do
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        if [ $help_flag = 0 ]; then
	        print_help
            exit 0
        fi
        shift
    elif [ "$1" = "-a" ]; then
        shift
        #echo "found -a"
        if [[ "$1" =~ [0-9]{4}-[0-9]{2}-[0-9]{2}[" "]{1}[0-9]{2}:[0-9]{2}:[0-9]{2} ]]; then
            a_DATETIME="$1"
            shift
        else
            echo "Wrong date format input for filter -a. Treated as an error."
            echo "Required format: \"YYYY-MM-DD HH:MM:SS\""
            exit 0
        fi
    elif [ "$1" = "-b" ]; then
        shift
        #echo "found -b"
        if [[ "$1" =~ [0-9]{4}-[0-9]{2}-[0-9]{2}[" "]{1}[0-9]{2}:[0-9]{2}:[0-9]{2} ]]; then
            b_DATETIME="$1"
            shift
        else
            echo "Wrong date format input for filter -b. Treated as an error."
            echo "Required format: \"YYYY-MM-DD HH:MM:SS\""
            exit 0
        fi
    elif [ "$1" = "-t" ]; then
        shift
        echo "found -t"
    elif [ "$1" = "-w" ]; then
        if [ $w_flag = 1 ]; then
            echo "filter '-w' used more than once, which is regarded as error. Program will shut down."
            exit 0
        fi
        w_flag=1
        shift
        echo "found -w"
    elif [[ "$1" == -* ]]; then
        echo "an attempt at inputting a parameter was made, but sadly, the program didn't recognize '$1'."
        echo "Please refer to -h for more info. Program will shut down."
        exit 0
    else
        break
    fi
    if [ $help_flag = 0 ]; then
        help_flag=1
    fi
done

comm_flag=0
comm_msg_flag=0
i=0

#=====================================================================
#                           COMMAND PARSING
#=====================================================================
until [ $i -gt 1 ] # will go through twice just to check whether next arg isn't a command as well (forbidden situation) 
do
    if [ "$1" = "list-tick" ]; then
	    shift
        if [ $comm_flag = 1 ]; then
            echo "ERROR: there can only be one command input. Program will shut down."
            exit 0
        fi
        comm_flag=1
        echo "found list-tick"
    elif [ "$1" = "profit" ]; then
        shift
        if [ $comm_flag = 1 ]; then
            echo "ERROR: there can only be one command input. Program will shut down."
            exit 0
        fi
        comm_flag=1
        echo "found profit"
    elif [ "$1" = "pos" ]; then
        shift
        if [ $comm_flag = 1 ]; then
            echo "ERROR: there can only be one command input. Program will shut down."
            exit 0
        fi
        comm_flag=1
        echo "found pos"
    elif [ "$1" = "last-price" ]; then
        shift
        if [ $comm_flag = 1 ]; then
            echo "ERROR: there can only be one command input. Program will shut down."
            exit 0
        fi
        comm_flag=1
        echo "found last-price"
    elif [ "$1" = "list-ord" ]; then
        shift
        if [ $comm_flag = 1 ]; then
            echo "ERROR: there can only be one command input. Program will shut down."
            exit 0
        fi
        comm_flag=1
        echo "found list-ord"
    elif [ "$1" = "graph-pos" ]; then
        shift
        if [ $comm_flag = 1 ]; then
            echo "ERROR: there can only be one command input. Program will shut down."
            exit 0
        fi
        comm_flag=1
        echo "found graph-pos"
    else
        if [ $comm_msg_flag = 0 ]; then
            echo "no command input."
        fi
    fi
    #echo "$i"
    comm_msg_flag=1
    i=$((i+1))
done

#GZ_flag=0
GZ_READ_INPUT=""
READ_INPUT="cat $param - | sort"

#=====================================================================
#                           LOAD LOGS
#=====================================================================

#log=("$(ls -d $1)")
#for param in "${log[@]}"; do
#    if [[ "$param" =~ .gz$ ]]; then
#        GZ_READ_INPUT="gzip -d -c $GZIP | $param - | sort"
#        #GZ_flag=1
#    else
#        READ_INPUT="cat $param | sort"
#    fi
#done

logs="" #variable to load logs into

if [[ "$1" =~ .gz$ ]]; then
    logs=($(gzip -d -c $list)) #if the input is zipped, load it like this (NOT TESTED YET AND I'M NOT EVEN GONNA UNTIL I'VE MADE THE PROGRAM WORK WITHOUT)
elif [[ "$1" =~ .log$ ]]; then
    logs=($(ls -d $1)) #if the input is normal log file, load whole log into this variable
else
    echo ""
    #read logs from input, I'll get back to this if I have spare time (very unlikely)
fi

#I WILL ALSO HAVE TO IMPLEMENT MULTIPLE LOGS LOADING, PROBABLY SHIFT HERE AND CHECK IF THERE'S ANY OTHER INPUT AFTER THE FIRST LOG WAS LOADED AND
#IF THERE IS THEN JUST CONCATENATE IT TO WHAT HAS ALREADY BEEN LOADED

#=====================================================================
#                           COMMANDS EXECUTION
#=====================================================================
while read -r line; do #if the input was a normal log file, this is how to read it from our copy line by line
#which means that here, I will be executing the commands... is this done then? have I figured it out? could it be that easy? only time will tell...
    #LOADS ONLY LINES WITHIN SET -a AND -b
    logs=$(awk -F ';' -v l="$line" -v a="$a_DATETIME" -v b="$b_DATETIME" '{if ( ($1 > a) && ($1 < b) ) { print $line }}')
    #TODO: -t
    #FINAL_OUTPUT=$(awk -F ';' -v l="$line" -v t="$TICKERS" ' ')        NĚCO TAKOVÉHO ASI??
done < "$logs"

echo ""
echo "$logs"
echo ""



TICKS_FILTER="grep '^.*;\($TICKERS\)'"
#READ_FILTERED="eval $READ_INPUT | awk -F ';' 'if (\$1 > $a_DATETIME &&) {print \$0}' | eval $TICKS_FILTER"    #';' is separator(delimiter)

echo "-a date is $a_DATETIME"
echo "-b date is $b_DATETIME"

#GZ_READ_INPUT="gzip -d -c $GZIP | cat $LOG_FILES - | sort"
#READ_INPUT="cat $LOG_FILES - | sort"
#NO_INPUT="cat"
#NOTICKS_FILTER="cat"