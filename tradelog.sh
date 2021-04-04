#!/bin/bash

# file tradelog.sh
# Author: Vojtěch Kališ, xkalis03.stud.fit.vutbr.cz
# Project #1 for VUT FIT - IOS (Operating Systems)
# TASK: Script for log analysis

#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#!!!!!TODO: CLEAN ALL THE USELESS COMMENTS BEFORE YOU TURN THE PROJECT IN!!!!!
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

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

a_datetime="0000-00-00 00:00:00"    # initialize to a value where everything will be after this date
                                    # (alternatively, an empty string would suffice)
b_datetime="9999-99-99 99:99:99"    # initialize to a value where everything will be before this date
width=1000
w_flag=0
help_flag=0

newline=$'\n'

declare -a tickers_arr

tickers=""
tickers_flag=0
tickers_cnt=0
command=""                          # variable for loaded command (CAN ALWAYS BE ONLY ONE)
first_line=""
first_flag=0

comm_flag=0
comm_msg_flag=0
i=0

value=0
sum=0

#=====================================================================
#                           FILTERS PARSING
#=====================================================================
for param in "$@"; do
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        if [ $help_flag = 0 ]; then
	        print_help
            exit 0
        else 
            echo "Wrong order of arguments input. Program found call for 'help' which wasn't entered as the first argument."
            echo "Program will shut down. For correct 'help' call, please use '-h' or '--help' as the first argument."
            exit 0
        fi
        shift
    elif [ "$1" = "-a" ]; then
        shift
        #echo "found -a"
        if [[ "$1" =~ [0-9]{4}-[0-9]{2}-[0-9]{2}[" "]{1}[0-9]{2}:[0-9]{2}:[0-9]{2} ]]; then
            a_datetime="$1"
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
            b_datetime="$1"
            shift
        else
            echo "Wrong date format input for filter -b. Treated as an error. Program will shut down."
            echo "Required format: \"YYYY-MM-DD HH:MM:SS\""
            exit 0
        fi
    elif [ "$1" = "-t" ]; then
        shift
        if [ $tickers_flag = 0 ]; then
            tickers_flag=1
            tickers="$1"
        else
            #tickers="${tickers}${newline}$1"
            tickers="${tickers};$1"
        fi
        tickers_cnt=$((tickers_cnt+1))
        #tickers_arr[$tickers_cnt]=$1
        shift
    elif [ "$1" = "-w" ]; then
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
    elif [[ "$1" == -* ]]; then
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
until [ $i -gt 1 ] # will go through twice just to check whether next arg isn't a command as well (forbidden situation) 
do
    if [ "$1" = "list-tick" ]; then
        if [ $comm_flag = 1 ]; then
            echo "ERROR: there can only be one command input. Program will shut down."
            exit 0
        fi
        command="$1"
        comm_flag=1
        #echo "found list-tick"
	    shift
    elif [ "$1" = "profit" ]; then
        if [ $comm_flag = 1 ]; then
            echo "ERROR: there can only be one command input. Program will shut down."
            exit 0
        fi
        command="$1"
        comm_flag=1
        #echo "found profit"
        shift
    elif [ "$1" = "pos" ]; then
        if [ $comm_flag = 1 ]; then
            echo "ERROR: there can only be one command input. Program will shut down."
            exit 0
        fi
        command="$1"
        comm_flag=1
        #echo "found pos"
        shift
    elif [ "$1" = "last-price" ]; then
        if [ $comm_flag = 1 ]; then
            echo "ERROR: there can only be one command input. Program will shut down."
            exit 0
        fi
        command="$1"
        comm_flag=1
        #echo "found last-price"
        shift
    elif [ "$1" = "hist-ord" ]; then
        if [ $comm_flag = 1 ]; then
            echo "ERROR: there can only be one command input. Program will shut down."
            exit 0
        fi
        command="$1"
        comm_flag=1
        #echo "found list-ord"
        shift
    elif [ "$1" = "graph-pos" ]; then
        if [ $comm_flag = 1 ]; then
            echo "ERROR: there can only be one command input. Program will shut down."
            exit 0
        fi
        command="$1"
        comm_flag=1
        #echo "found graph-pos"
        shift
    elif [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ "$1" = "-a" ] || [ "$1" = "-b" ] || [ "$1" = "-t" ]|| [ "$1" = "-w" ]; then
        echo "ERROR: wrong order of arguments input. Program will shut down."
        exit 0
    else
        if [ $comm_msg_flag = 0 ]; then
            #echo "no command input."
            iexistjusttofillthisline=0
        fi
    fi
    #echo "$i"
    comm_msg_flag=1
    i=$((i+1))
done

#GZ_flag=0

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
    logs=$(gzip -d -c $list) #if the input is zipped, load it like this (NOT TESTED YET AND I'M NOT EVEN GONNA UNTIL I'VE MADE THE PROGRAM WORK WITHOUT)
elif [[ "$1" =~ .log$ ]]; then
    logs=$(ls -d $1) #if the input is normal log file, load whole log into this variable
else
    echo ""
    #read logs from input, I'll get back to this if I have spare time (very unlikely)
fi

#I WILL ALSO HAVE TO IMPLEMENT MULTIPLE LOGS LOADING, PROBABLY SHIFT HERE AND CHECK IF THERE'S ANY OTHER INPUT AFTER THE FIRST LOG WAS LOADED AND
#IF THERE IS THEN JUST CONCATENATE IT TO WHAT HAS ALREADY BEEN LOADED

#=====================================================================
#                           FILTERS EXECUTION
#=====================================================================
#the 'awk' in the 'while read' loop didn't want to read the first line of log, so I had to improvise.
first_line=""
first_line=$(gawk 'NR == 1' $logs)
first_line_test=""
first_line_test=$(gawk 'NR == 1' $logs | awk -F ';' -v a="$a_datetime" -v b="$b_datetime" -v tickers="$tickers" -v cnt="$tickers_cnt" -v first="$first_line" '{ split(tickers,tickers_split,";");
{if ( cnt == 0 ) { cnt=1 } } {for (i = cnt; i > 0; i--) {if ( ($1 > a) && ($1 < b) && (( $2 == tickers_split[i] ) || ( tickers == "" ))) { print first }}}}')

while read -r line; do #if the input was a normal log file, this is how to read it from our copy line by line
#which means that here, I will be executing the commands... is this done then? have I figured it out? could it be that easy? only time will tell...
    #!!!NEED TO FIGURE OUT HOW TO PROCESS FIRST LINE AS WELL
    #maybe with BEGIN?
    logs_filtered=$(gawk -F ';' -v a="$a_datetime" -v b="$b_datetime" -v tickers="$tickers" -v cnt="$tickers_cnt" '{ split(tickers,tickers_split,";");
    {if ( cnt == 0 ) { cnt=1 } } {for (i = cnt; i > 0; i--) {if ( ($1 > a) && ($1 < b) && (( $2 == tickers_split[i] ) || ( tickers == "" ))) { print $line }}}}' | sort | uniq )
    if [ "$first_line_test" != "" ]; then #if first line of log met the criteria as well
        if [ "$logs_filtered" != "" ]; then
            logs_filtered="${first_line_test}${newline}${logs_filtered}"
        else
            logs_filtered="$first_line_test"
        fi
    fi
done < "$logs"

#=====================================================================
#                           COMMAND EXECUTION
#=====================================================================
logs_filtered="${newline}${logs_filtered}" #because the 'awk' in the following 'while read' loop refuses to read the first line again.
                                           #however, this time around, I can simply use a cheeky workaround (still probably not the best
                                           #solution possible, I should have probably ditched the 'while read' for something better ages
                                           #ago, but hey - it works, and I'm on a strict time schedule, so I have to cut some corners.)

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
        uniq_tickers=$(gawk -F ';' '{ print $2 }' | sort | uniq ) # basically do 'list-tick' to get all unique tickers
        uniq_tickers="${newline}${uniq_tickers}"
        #while read -r line; do
        #    num_of_uniques=$(gawk -F ';' '{ num_of_uniques+=1 } END{ printf "%d",num_of_uniques }')
        #done <<< "$uniq_tickers"
        while read -r line; do
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
        while read -r line; do
            longest=$(gawk -F ':' 'BEGIN{ sum=0 } {if ( length($2) > sum ) { sum=length($2) }} END{printf "%d",sum}')
        done <<< "$logs_filtered2"

        echo "$logs_filtered2" | gawk -F ':' -v dist="$longest" -v space=" " '{ if (NR!=1) {{ printf "%-9s : ",$1 } {num=dist-length($2)} { printf "%*s%.2f\n",num,"",$2 }}}'
        exit 0
    #=== last-price ===#
    elif [ "$command" = "last-price" ]; then
        uniq_tickers=$(gawk -F ';' '{ print $2 }' | sort | uniq ) # basically do 'list-tick' to get all unique tickers
        uniq_tickers="${newline}${uniq_tickers}"

        while read -r line; do
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
        while read -r line; do
            longest=$(gawk -F ':' 'BEGIN{ sum=0 } {if ( length($2) > sum ) { sum=length($2) }} END{printf "%d",sum}')
        done <<< "$logs_filtered2"

        echo "$logs_filtered2" | gawk -F ':' -v dist="$longest" -v space=" " '{ if (NR!=1) {{ printf "%-9s : ",$1 } {num=dist-length($2)} { printf "%*s%.2f\n",num,"",$2 }}}'
        exit 0
    #==== hist-ord ====#
    elif [ "$command" = "hist-ord" ]; then
        uniq_tickers=$(gawk -F ';' '{ print $2 }' | sort | uniq ) # basically do 'list-tick' to get all unique tickers
        uniq_tickers="${newline}${uniq_tickers}"

        while read -r line; do
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
        #while read -r line; do
        #    num_of_uniques=$(gawk -F ';' '{ num_of_uniques+=1 } END{ printf "%d",num_of_uniques }')
        #done <<< "$uniq_tickers"
        while read -r line; do
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
        while read -r line; do
            biggest=$(gawk -F ':' 'BEGIN{ sum=0 }
                                    function abs(x){return ((x < 0.0) ? -x : x)} 
                                    {if ( abs($2) > sum ) { sum=abs($2) }} END{printf "%.2f",sum}')
        done <<< "$logs_filtered2"
        #echo "$biggest"
        #echo "$width"

        echo "$logs_filtered2" | gawk -F ':' -v biggest="$biggest" -v width="$width" -v space=" " 'function abs(x){return ((x < 0.0) ? -x : x)} 
                                                                                { if (NR!=1) {
                                                                                    { printf "%-9s : ",$1 } 
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
#U příkazů hist-ord a graph-pos je za dvojtečkou na všech řádcích právě jedna mezera (případně žádná, pokud v pravém sloupci daného řádku nic není)
#Hodnota aktuálně držených pozic (příkazy pos a graph-pos) se pro každý ticker spočítá jako počet držených jednotek * jednotková cena 
#   z poslední transakce, kde počet držených jednotek je dán jako suma objemů buy transakcí - suma objemů sell transakcí.
#Pokud není při použití příkazu hist-ord uvedena šířka WIDTH, pak každá pozice v histogramu odpovídá jedné transakci.
#Pokud není při použití příkazu graph-pos uvedena šířka WIDTH, pak každá pozice v histogramu odpovídá hodnotě 1000 (zaokrouhleno na 
#   tisíce směrem k nule, tj. hodnota 2000 bude reprezentována jako ## zatímco hodnota 1999.99 jako # a hodnota -1999.99 jako !.
#U příkazů hist-ord a graph-pos s uvedenou šířkou WIDTH při dělení zaokrouhlujte směrem k nule (tedy např. při graph-pos -w 6 a 
#   nejdelším řádku s hodnotou 1234 bude řádek s hodnotou 1234 vypadat takto ######, řádek s hodnotou 1233.99 takto ##### a řádek s 
#   hodnotou -1233.99 takto !!!!!).

#=====================================================================
#                               PRINTS
#=====================================================================

echo "$logs_filtered" | gawk '{if (NR!=1) {print}}' #BECAUSE MY SOLUTION SADLY LEAVES AN EMPTY LINE AT THE TOP, I HAVE TO PRINT THE RESULTS OUT LIKE THIS

#echo "=========="
#echo "logs are: $logs"
#echo "=========="
#echo "OUTPUT (without command)"
#echo ""
#echo "$logs_filtered"
#echo "=========="
#echo "OUTPUT (without command and first line)"
#echo ""
#echo "$logs_filtered" | gawk '{if (NR!=1) {print}}' #BECAUSE MY SOLUTION SADLY LEAVES AN EMPTY LINE AT THE TOP, I HAVE TO PRINT THE RESULTS OUT LIKE THIS
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

#GZ_READ_INPUT="gzip -d -c $GZIP | cat $LOG_FILES - | sort"
#READ_INPUT="cat $LOG_FILES - | sort"
#NO_INPUT="cat"
#NOTICKS_FILTER="cat"