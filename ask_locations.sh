#!/bin/bash
for num in $(seq 1 "$1")
do
    until xinput --query-state 12 | grep -c "button\[1\]=down" > /dev/null
    do
        :
    done
    echo $(xdotool getmouselocation --shell)
    until xinput --query-state 12 | grep -c "button\[1\]=up" > /dev/null
    do
        :
    done
done

