#!/bin/bash

#=====================================================================
# file tradelog.sh
# Author: Vojtěch Kališ, xkalis03.stud.fit.vutbr.cz
# Project #1 for VUT FIT - IOS (Operating Systems)
# TASK: Script for log analysis
#=====================================================================

# LORD GIVE ME THE MENTAL CAPACITY TO REMEMBER THESE, but in the meantime, this cheatsheet should suffice.
#
# GitHub push flow:   $ git add .
#                     $ git commit -m "message"
#                     $ git push --set-upstream origin main   (where 'main' is name of branch to commit to)
#
# !!!(Forces local file overwrite)!!!
# GitHub pull flow:   $ git fetch origin main
#                     $ git reset --hard origin/main

#TODO: loading from both normal logs and zipped ones

export POSIXLY_CORRECT=yes
export LC_NUMERIC=en_US.UTF-8

#function for 'help' printing, pretty self-explanatory
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

#variable for filtering, program will only print logs AFTER this date
a_datetime="0000-00-00 00:00:00"    # initialize to a value where everything will be after this date
                                    # (alternatively, an empty string would suffice)
#variable for filtering, program will only print logs BEFORE this date                                    
b_datetime="9999-99-99 99:99:99"    # initialize to a value where everything will be before this date

#width for 'graph-pos' and 'hist-ord', as per the task description it is to be defaultly set to 1000
#(which just prints '#' and '!' like, everywhere, jesus, it's like a flood, but the customer's the boss I guess)
width=1000
#a simple flag telling us that width was set to something else (as it should be- okay, okay, I'll shut up...)
w_flag=0

#a flag telling us help call was found
help_flag=0

#this is just defining a newline character - not sure why I did so anymore, maybe I wanted to be fancy?
newline=$'\n'

#variable to save the loaded tickers into; if you look closely at around line 135, I separate them by the character ';',
#which is used as a delimiter for awk in FILTERS EXECUTION (scroll down to find the header)
tickers=""
#this is a flag simply just to determine whether any filter has already been loaded before; which is used in delimiter ';' printing
tickers_flag=0
#simple counter, counts how many tickers have been loaded
tickers_cnt=0

#variable to save the loaded command into
command=""

#flag, used in command parsing; since only one command can be input at one time, this flag gets set to '1' after one is loaded and if the 
#next argument is a command as well, the program will, thanks to this flag, recognize there are two command inputs and ceases its function
comm_flag=0

#this flag is useless, ignore it
comm_msg_flag=0

#=====================================================================
#                           FILTERS PARSING
#=====================================================================
#the following loop reads arguments from stdin and tries to match them with pre-defined filters, all the way until what it loads
#   isn't recognized, in which case it moves to parsing command (look for COMMAND PARSING header below, it's huge, you can't miss it)
#'help' call is handled in this loop as well, for the sake of simplicity
#TO READ ON WHAT EACH FILTER DOES, please scroll all the way up to the 'help' message
#NOTE: it can be quite useful to read the error messages as well

for param in "$@"; do
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then #found -h or --help
        if [ $help_flag = 0 ]; then
	        print_help
            exit 0
        else 
            echo "Wrong order of arguments input. Program found call for 'help' which wasn't entered as the first argument."
            echo "Program will shut down. For correct 'help' call, please use '-h' or '--help' as the first argument."
            exit 0
        fi
        shift
    elif [ "$1" = "-a" ]; then  #found -a
        shift
        #echo "found -a"
        if [[ "$1" =~ [0-9]{4}-[0-9]{2}-[0-9]{2}[" "]{1}[0-9]{2}:[0-9]{2}:[0-9]{2} ]]; then #making sure the correct format of date is used
            a_datetime="$1"
            shift
        else
            echo "Wrong date format input for filter -a. Treated as an error."
            echo "Required format: \"YYYY-MM-DD HH:MM:SS\""
            exit 0
        fi
    elif [ "$1" = "-b" ]; then  #found -b
        shift
        #echo "found -b"
        if [[ "$1" =~ [0-9]{4}-[0-9]{2}-[0-9]{2}[" "]{1}[0-9]{2}:[0-9]{2}:[0-9]{2} ]]; then #making sure the correct format of date is used
            b_datetime="$1"
            shift
        else
            echo "Wrong date format input for filter -b. Treated as an error. Program will shut down."
            echo "Required format: \"YYYY-MM-DD HH:MM:SS\""
            exit 0
        fi
    elif [ "$1" = "-t" ]; then  #found -t
        shift
        #echo "found -t"
        if [ $tickers_flag = 0 ]; then
            tickers_flag=1
            tickers="$1"
        else
            tickers="${tickers};$1"
        fi
        tickers_cnt=$((tickers_cnt+1))
        shift
    elif [ "$1" = "-w" ]; then  #found -w
        #echo "found -w"
        shift
        if [ $w_flag = 1 ]; then
            echo "Filter '-w' used more than once, which is treated as an error. Program will shut down."
            exit 0
        fi
        if [[ "$1" < 0 ]] || [[ "$1" = 0 ]]; then
            echo "The argument for '-w' is a number which isn't greater than 0. Program will shut down."
            echo "Please refer to 'help', called with '-h' or '--help', for more information."
            exit 0
        elif [[ "$1" =~ [0-9]{1,20} ]]; then
            w_flag=1
            width="$1"
        else
            echo "The argument for '-w' is NaN. Treated as an error. Program will shut down."
            exit 0
        fi
        shift
    elif [[ "$1" == -* ]]; then     #found something starting with a dash, but it wasn't recognized - maybe a typo?
        echo "An attempt at inputting a parameter was made, but sadly, the program either didn't recognize '$1'."
        echo "Please refer to -h for more info. Program will shut down."
        exit 0
    else
        break
    fi
    if [ $help_flag = 0 ]; then
        help_flag=1
    fi
done

#=====================================================================
#                           COMMAND PARSING
#=====================================================================
#the following loop (which only really loops twice) reads arguments from stdin and tries to match them with pre-defined commands
#TO READ ON WHAT EACH COMMAND DOES, please scroll all the way up to the 'help' message
#NOTE: it can be quite useful to read the error messages as well

i=0 #i is set to 0 and then incremented after each loop, until it's greater than 1 (meaning two loops will be executed)
until [ $i -gt 1 ] # will go through twice just to check whether next arg isn't a command as well (forbidden situation) 
do
    if [ "$1" = "list-tick" ]; then #found list-tick
        if [ $comm_flag = 1 ]; then
            echo "ERROR: there can only be one command input. Program will shut down."
            exit 0
        fi
        command="$1"
        comm_flag=1
        #echo "found list-tick"
	    shift
    elif [ "$1" = "profit" ]; then  #found profit
        if [ $comm_flag = 1 ]; then
            echo "ERROR: there can only be one command input. Program will shut down."
            exit 0
        fi
        command="$1"
        comm_flag=1
        #echo "found profit"
        shift
    elif [ "$1" = "pos" ]; then     #found pos
        if [ $comm_flag = 1 ]; then
            echo "ERROR: there can only be one command input. Program will shut down."
            exit 0
        fi
        command="$1"
        comm_flag=1
        #echo "found pos"
        shift
    elif [ "$1" = "last-price" ]; then  #found last-price
        if [ $comm_flag = 1 ]; then
            echo "ERROR: there can only be one command input. Program will shut down."
            exit 0
        fi
        command="$1"
        comm_flag=1
        #echo "found last-price"
        shift
    elif [ "$1" = "hist-ord" ]; then    #found hist-ord
        if [ $comm_flag = 1 ]; then
            echo "ERROR: there can only be one command input. Program will shut down."
            exit 0
        fi
        command="$1"
        comm_flag=1
        #echo "found list-ord"
        shift
    elif [ "$1" = "graph-pos" ]; then   #found graph-pos
        if [ $comm_flag = 1 ]; then
            echo "ERROR: there can only be one command input. Program will shut down."
            exit 0
        fi
        command="$1"
        comm_flag=1
        #echo "found graph-pos"
        shift
    #found that while looking for arguments, we found a filter (which means the arguments were put in in the wrong order)
    #now, the task description specifies that we are to assume this situation will never happen and thus don't need to treat it,
    #but I like to make life difficult for myself (not really, this is very easy to implement) and thus, here it is; woosh~
    elif [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ "$1" = "-a" ] || [ "$1" = "-b" ] || [ "$1" = "-t" ]|| [ "$1" = "-w" ]; then
        echo "ERROR: wrong order of arguments input. Program will shut down."
        exit 0
    else
        if [ $comm_msg_flag = 0 ]; then
            #echo "no command input."
            iexistjusttofillthisline=0  #this was here just for the 'echo' up above, I don't really need this 'else' branch anymore...
                                        #however, its existence isn't really hurting anyone, is it? why not just let it live?  :^)
        fi
    fi
    #echo "$i"
    comm_msg_flag=1
    i=$((i+1))  #i++ but in a special, bash way (cuz bash be special like that)
done

#=====================================================================
#                           LOAD LOGS
#=====================================================================

logs=""         #variable to load logs into
found_logs=0    #counts the number of logs loaded from input
#the following are all just flags
stdin_flag=0    #we found there are no logs (read from stdin)
morethanone_flag=0  #we found there are more than one logs to be read

declare -a logs_arr #this is a bash array, into which we load all logs found in stdin

for param in "$@"; do
    if [[ "$1" =~ .gz$ ]]; then     #if the input is zipped, load it like this
        if [ "$found_logs" = 0 ]; then
            logs_arr[$found_logs]="$1"
        else
            logs_arr[$found_logs]="$1"
        fi
        found_logs=$((found_logs+1))
        shift
    elif [[ "$1" =~ .log$ ]]; then  #if the input is normal log file, load its name into this variable
        if [ "$found_logs" = 0 ]; then
            logs_arr[$found_logs]="$1"
        else
            logs_arr[$found_logs]="$1"
        fi
        found_logs=$((found_logs+1))
        shift
    fi
done

#=====================================================================
#                           FILTERS EXECUTION
#=====================================================================
#the following 'while' loop loops through all loaded logs, applies all filters to what was loaded and then concatenates the results
#the loop will execute enough times to loop through all logs found in stdin (the names of which we already saved into an array, in
#the section above)

if [ "$found_logs" = 0 ]; then  #if no logs loaded, read logs from input
    stdin_flag=1
    found_logs=1
fi
cnt="$found_logs"
cnt=$((cnt-1))

while [ $cnt -gt -1 ]; do
    if [ "$stdin_flag" = 1 ]; then  #loading from stdin
        logs_filtered=$(gawk -F ';' -v a="$a_datetime" -v b="$b_datetime" -v tickers="$tickers" -v cnt="$tickers_cnt" '{ split(tickers,tickers_split,";");
        {if ( cnt == 0 ) { cnt=1 } } {for (i = cnt; i > 0; i--) {if ( ($1 > a) && ($1 < b) && (( $2 == tickers_split[i] ) || ( tickers == "" ))) { print $line }}}}' | sort | uniq )
        break
    elif [[ "${logs_arr[$cnt]}" =~ .gz$ ]]; then #loading a zipped file
        logs_filtered3=$(gunzip -c "${logs_arr[$cnt]}" | gawk -F ';' -v a="$a_datetime" -v b="$b_datetime" -v tickers="$tickers" -v cnt="$tickers_cnt" '{ split(tickers,tickers_split,";");
        {if ( cnt == 0 ) { cnt=1 } } {for (i = cnt; i > 0; i--) {if ( ($1 > a) && ($1 < b) && (( $2 == tickers_split[i] ) || ( tickers == "" ))) { print $line }}}}' | sort | uniq )
    else    #loading a regular log
        logs_filtered3=$(gawk -F ';' -v a="$a_datetime" -v b="$b_datetime" -v tickers="$tickers" -v cnt="$tickers_cnt" '{ split(tickers,tickers_split,";");
        {if ( cnt == 0 ) { cnt=1 } } {for (i = cnt; i > 0; i--) {if ( ($1 > a) && ($1 < b) && (( $2 == tickers_split[i] ) || ( tickers == "" ))) { print $line }}}}' "${logs_arr[$cnt]}" | sort | uniq )
    fi
    if [ "$morethanone_flag" = 1 ]; then
        logs_filtered="${logs_filtered}${newline}${logs_filtered3}"
    else
        logs_filtered="${logs_filtered3}"
    fi
    morethanone_flag=1
    ((cnt--))
done

if [ "$logs_filtered" = "" ] && [ "$command" != "profit" ]; then #if nothing remained from logs after the filter, and command isn't 'profit'
    #echo "nothing to be done."
    exit 0
fi

#=====================================================================
#                           COMMAND EXECUTION
#=====================================================================
logs_filtered="${newline}${logs_filtered}" #because the 'awk' in the following 'while read' loop refuses to read the first line.
                                           #this simple cheeky workaround can be used

while read -r line; do
    #==== list-tick ===#
    if [ "$command" = "list-tick" ]; then
        logs_filtered2=$(gawk -F ';' '{ print $2 }' | sort | uniq )
        echo "$logs_filtered2"
        exit 0
    #===== profit =====#
    elif [ "$command" = "profit" ]; then
        sum=$(gawk -F ';' '{ if ( $3 == "sell" ){ sum+=( $4*$6 )} else { if ($3 == "buy") { sum-=( $4*$6 ) }} } END{ printf "%.2f\n",sum }')
        echo "$sum"
        exit 0
    #======= pos ======#
    elif [ "$command" = "pos" ]; then
        uniq_tickers=$(gawk -F ';' '{ print $2 }' | sort | uniq ) #basically do 'list-tick' to get all unique tickers
        uniq_tickers="${newline}${uniq_tickers}"

        while read -r line; do  #print all the unique tickers in one line so it can then be parsed to awk and separated there
            uniq_tickers_oneline=$(gawk 'BEGIN { ORS=";" }; { print $1 }')
        done <<< "$uniq_tickers"

        while read -r line; do
        logs_filtered2=$(gawk -F ';' -v tickers="$uniq_tickers_oneline" 'BEGIN{ split(tickers,tickers_val,";"); for (x in tickers_val){ tickers_split[tickers_val[x]]=0;}}
                                                                            {{ for (x in tickers_split) { 
                                                                                if ($2 == x) {
                                                                                    if ($3 == "buy" ) { 
                                                                                        tickers_split[x]+= $6
                                                                                        tickers_val[x]= $4
                                                                                    } 
                                                                                    else { if ($3 == "sell" ) { 
                                                                                        tickers_split[x]-= $6
                                                                                        tickers_val[x]= $4
                                                                                        }   
                                                                                    }
                                                                                }}
                                                                            }} 
                                                                            END{ for (ticker in tickers_split) {if (ticker != "") {{ 
                                                                                tickers_split[ticker]*=tickers_val[ticker] }
                                                                                printf "%s:%.2f\n", ticker,tickers_split[ticker] 
                                                                            }}}' | sort -n -r -t':' -k2 )
        done <<< "$logs_filtered"
        logs_filtered2="${newline}${logs_filtered2}"
        while read -r line; do  #find the longest number, this information is used for proper alignment after
            longest=$(gawk -F ':' 'BEGIN{ sum=0 } {if ( length($2) > sum ) { sum=length($2) }} END{printf "%d",sum}')
        done <<< "$logs_filtered2"

        echo "$logs_filtered2" | gawk -F ':' -v dist="$longest" -v space=" " '{ if (NR!=1) {{ printf "%-9s : ",$1 } {num=dist-length($2)} { printf "%*s%.2f\n",num,"",$2 }}}'
        exit 0
    #=== last-price ===#
    elif [ "$command" = "last-price" ]; then
        uniq_tickers=$(gawk -F ';' '{ print $2 }' | sort | uniq ) #basically do 'list-tick' to get all unique tickers
        uniq_tickers="${newline}${uniq_tickers}"

        while read -r line; do  #print all the unique tickers in one line so it can then be parsed to awk and separated there
            uniq_tickers_oneline=$(gawk 'BEGIN { ORS=";" }; { print $1 }')
        done <<< "$uniq_tickers"

        while read -r line; do
        logs_filtered2=$(gawk -F ';' -v tickers="$uniq_tickers_oneline" 'BEGIN{ split(tickers,tickers_val,";"); for (x in tickers_val){ tickers_split[tickers_val[x]]=0;}}
                                                                            {{ for (x in tickers_split) { 
                                                                                if ($2 == x) {
                                                                                    tickers_val[x]= $4
                                                                                }}
                                                                            }} 
                                                                            END{ for (ticker in tickers_split) {if (ticker != "") {
                                                                                printf "%s:%.2f\n", ticker,tickers_val[ticker] 
                                                                            }}}' | sort -n -t':' -k1 )
        done <<< "$logs_filtered"
        logs_filtered2="${newline}${logs_filtered2}"
        while read -r line; do  #find the longest number, this information is used for proper alignment after
            longest=$(gawk -F ':' 'BEGIN{ sum=0 } {if ( length($2) > sum ) { sum=length($2) }} END{printf "%d",sum}')
        done <<< "$logs_filtered2"

        echo "$logs_filtered2" | gawk -F ':' -v dist="$longest" -v space=" " '{ if (NR!=1) {{ printf "%-9s : ",$1 } {num=dist-length($2)} { printf "%*s%.2f\n",num,"",$2 }}}'
        exit 0
    #==== hist-ord ====#
    elif [ "$command" = "hist-ord" ]; then
        uniq_tickers=$(gawk -F ';' '{ print $2 }' | sort | uniq ) # basically do 'list-tick' to get all unique tickers
        uniq_tickers="${newline}${uniq_tickers}"

        while read -r line; do  #print all the unique tickers in one line so it can then be parsed to awk and separated there
            uniq_tickers_oneline=$(gawk 'BEGIN { ORS=";" }; { print $1 }')
        done <<< "$uniq_tickers"

        while read -r line; do
        logs_filtered2=$(gawk -F ';' -v tickers="$uniq_tickers_oneline" 'BEGIN{ split(tickers,tickers_val,";"); for (x in tickers_val){ tickers_split[tickers_val[x]]=0;}}
                                                                            {{ for (x in tickers_split) { 
                                                                                if ($2 == x) {
                                                                                    tickers_val[x]+=1
                                                                                }}
                                                                            }} 
                                                                            END{ for (ticker in tickers_split) {if (ticker != "") {
                                                                                printf "%s:%d\n", ticker,tickers_val[ticker] 
                                                                            }}}' | sort -n -t':' -k1 )
        done <<< "$logs_filtered"

        echo "$logs_filtered2" | gawk -F ':' -v space=" " -v width="$width" '{ { printf "%-9s :",$1 } {i=$2} 
                                                                            {if ( i > width )
                                                                                {i=width}} 
                                                                            { if (i!=0)
                                                                                {printf " "} 
                                                                            for (i; i>0; i--){ 
                                                                                printf "#" }} 
                                                                            { printf "\n" }}'
        exit 0
    #==== graph-pos ===#
    elif [ "$command" = "graph-pos" ]; then
        uniq_tickers=$(gawk -F ';' '{ print $2 }' | sort | uniq ) # basically do 'list-tick' to get all unique tickers
        uniq_tickers="${newline}${uniq_tickers}"

        while read -r line; do  #print all the unique tickers in one line so it can then be parsed to awk and separated there
            uniq_tickers_oneline=$(gawk 'BEGIN { ORS=";" }; { print $1 }')
        done <<< "$uniq_tickers"

        while read -r line; do
        logs_filtered2=$(gawk -F ';' -v tickers="$uniq_tickers_oneline" 'BEGIN{ split(tickers,tickers_val,";"); for (x in tickers_val){ tickers_split[tickers_val[x]]=0;}}
                                                                            {{ for (x in tickers_split) { 
                                                                                if ($2 == x) {
                                                                                    if ($3 == "buy" ) { 
                                                                                        tickers_split[x]+= $6
                                                                                        tickers_val[x]= $4
                                                                                    } 
                                                                                    else { if ($3 == "sell" ) { 
                                                                                        tickers_split[x]-= $6
                                                                                        tickers_val[x]= $4
                                                                                        }   
                                                                                    }
                                                                                }}
                                                                            }} 
                                                                            END{ for (ticker in tickers_split) {if (ticker != "") {{ 
                                                                                tickers_split[ticker]*=tickers_val[ticker] }
                                                                                printf "%s:%.2f\n", ticker,tickers_split[ticker] 
                                                                            }}}' | sort -n -t':' -k1 )
        done <<< "$logs_filtered"
        logs_filtered2="${newline}${logs_filtered2}"
        while read -r line; do  #find the biggest number (in absolute value), this information is used for proper cropping of graph width later
            biggest=$(gawk -F ':' 'BEGIN{ sum=0 }
                                    function abs(x){return ((x < 0.0) ? -x : x)} 
                                    {if ( abs($2) > sum ) { sum=abs($2) }} END{printf "%.2f",sum}')
        done <<< "$logs_filtered2"

        echo "$logs_filtered2" | gawk -F ':' -v biggest="$biggest" -v width="$width" -v space=" " 'function abs(x){return ((x < 0.0) ? -x : x)} 
                                                                                { if (NR!=1) {
                                                                                    { printf "%-9s :",$1 } 
                                                                                {i=abs(int(($2 * width) / biggest))} 
                                                                                { if (i!=0){printf " "} 
                                                                                for (i; i>0; i--){ 
                                                                                    if ($2 > 0){
                                                                                        printf "#" }
                                                                                    if ($2 < 0){
                                                                                        printf "!" }
                                                                                    }} { printf "\n" }}}'
        exit 0
    fi
done <<< "$logs_filtered"

#=====================================================================
#                               PRINTS
#=====================================================================
#I MAJORLY USED THIS SECTION TO HAVE BETTER CONTROL OVER WHAT I SAW ON MY STDOUT, IT IS BY ALL MEANS UNNECESSARY TO STUDY, AND 
#SERVES NO OTHER PURPOSE EXCEPT FOR THE ONE 'ECHO' BELOW WHICH ONLY PRINTS OUTPUT WHEN THERE WERE NO COMMANDS LOADED FROM STDIN

#if no commands were input, print just the filtered log
echo "$logs_filtered" | gawk '{if (NR!=1) {print}}' #because my solution sadly leaves an empty line at the top, I have to print the results out this way

#echo "=========="
#echo "logs are: $logs"
#echo "=========="
#echo "OUTPUT (without command)"
#echo ""
#echo "$logs_filtered"
#echo "=========="
#echo "OUTPUT (without command and first line)"
#echo ""
#echo "$logs_filtered" | gawk '{if (NR!=1) {print}}' #because my solution sadly leaves an empty line at the top, I have to print the results out this way
#echo "=========="
#echo "OUTPUT (with command)"
#echo ""
#echo "$logs_filtered2"
#echo "=========="
#echo "OUTPUT (with command and without first line)"
#echo ""
#echo "$logs_filtered2" | gawk '{if (NR!=1) {print}}'
#echo "=========="
#echo "tickers: $tickers"
#echo "number of tickers is $tickers_cnt"
#echo "=========="
#echo "-a date is $a_datetime"
#echo "-b date is $b_datetime"
#echo "=========="
#echo "width is $width"
#echo "=========="
#echo "command is $command"
#echo "=========="
#echo "sum is $sum"