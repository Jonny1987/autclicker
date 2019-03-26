#!/bin/bash

get_balance() {
    words=$(./get_words.sh $1 $2)
    balance=$(echo $words | grep -oP "[\d,]+\.\d{2}" | sed 's/,//g')
    if [[ -z $balance ]]
    then
        exit 1
    fi
    echo $balance
}

get_balance_iterate() {
    for i in {30..35}
    do
        balance=$(get_balance $1 $i)
        if [[ ! -z $balance ]]
        then
            threshold=$i
            echo $threshold >> threshold
            echo $balance
            exit
        fi
    done
    exit 1
}

# $a is the image
echo $(get_balance_iterate $1)
