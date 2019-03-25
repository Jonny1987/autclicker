#!/bin/bash
if [ $# -eq 1 ] && [ $1 == "-n" ]
then
    read -r bal_loc < <(slop -f "%g")
    declare -p bal_loc > test_vars
else
    source test_vars
fi
xdotool mousemove_relative 1 1
maim -g $bal_loc __.png -m 10
./get_balance.sh __.png
