#!/bin/bash

get_words() {
    convert -resize 800%  $1 _1.png
    convert -threshold $2% _1.png _2.png
    convert -resample 300 _2.png _3.png
    convert -resize 25% _3.png _.png
    tesseract --psm 7 _.png _ &> /dev/null
    echo "$(head -n 1 _.txt)" 
}

# $a is the image
if [ $# -eq 2 ] && [ $2 == "-n" ]
then
    read -r bal_loc < <(slop -f "%g")
    declare -p bal_loc > test_vars
else
    source test_vars
fi
xdotool mousemove_relative 1 1
maim -g $bal_loc __.png -m 10
echo $(get_words __.png $1)
