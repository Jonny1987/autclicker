#!/bin/bash

get_balance_return=""
get_balance() {
    words=$(./get_words.sh $1 $2)
    balance=$(echo $words | grep -oP "\d\d{0,2}(,\d{3})*\.\d{2}$" | sed 's/,//g')
    if [[ -z $balance ]]
    then
        return 1
    fi

    if [[ ! -z $new_possible_balance ]]
    then
        echo balance $balance >> get_balance_log
        echo prev_balance $prev_balance >> get_balance_log
        echo new_possible_balance $new_possible_balance >> get_balance_log
        if [[ $(echo "$balance == $prev_balance" | bc -l) -eq 1 ]] || [[ $(echo "$balance == $new_possible_balance" | bc -l) -eq 1 ]]
        then
            get_balance_return=$balance
        fi
    else
        get_balance_return=$balance
    fi
}

get_balance_iterate_return=""
get_balance_iterate() {
    for i in {30..45}
    do
        get_balance $1 $i

        if [[ ! -z $get_balance_return ]]
        then
            threshold=$i
            echo $threshold >> threshold
            get_balance_iterate_return=$get_balance_return
            return
        fi
    done
    return 1
}

# $1 is the image. $2 is optional previous balance
image=$1
if [ $# -eq 3 ]
then
    bet_size=$2
    prev_balance=$3
    new_possible_balance=$(echo "$prev_balance - $bet_size" | bc -l)
fi

get_balance_iterate $image
echo $get_balance_iterate_return

