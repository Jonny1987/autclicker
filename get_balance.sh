#!/bin/bash

get_words() {
    convert -resize 800%  $1 _1.png
    convert -threshold $2% _1.png _2.png
    convert -resample 300 _2.png _3.png
    convert -resize 25% _3.png _.png
    tesseract --psm 7 _.png _ &> /dev/null
    echo "$(head -n 1 _.txt)" 
}

get_balance() {
    words=$(get_words $1 $2)
    balance=${words##*£}
    if [[ $balance =~ ^[0-9]+\.[0-9]{2}$ ]]
    then
        echo $balance
        exit
    fi
    echo ""
}

get_balance_iterate() {
    for i in {30..40}
    do
        balance=$(get_balance $1 $i)
        if [ "$balance" != "" ]
        then
            echo $balance
            exit
        fi
    done
    exit 1
}

# $a is the image
get_balance_iterate $1

