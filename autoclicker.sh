#!/usr/bin/env bash
# hint: use "xdotool getmouselocation" to get values
## hold down Escape key to exit

#name=$1

ask_locations() {
    number_locations=$1
    X_return=()
    Y_return=()
    for num in $(seq 1 "$number_locations")
    do
        until xinput --query-state 12 | grep -c "button\[1\]=down" > /dev/null
        do
            :
        done
        eval "$(xdotool getmouselocation --shell)"
        X_return[$num]=$X
        Y_return[$num]=$Y
        until xinput --query-state 12 | grep -c "button\[1\]=up" > /dev/null
        do
            :
        done
    done
}

minimise_current_window() {
    xdotool windowminimize "$(xdotool getactivewindow)"
    sleep 0.5
}

pause_until_keypress() {
    while true
    do
        sleep 0.1
        keypress=$(xinput --query-state 16 | grep -c "key\[9\]=up")
        if [ "$keypress" == "1"  ]
            then
                break
        fi		
    done

    escape_pause=0
    while true
    do
        if [ $escape_pause -eq 10 ]
        then
            break
        fi

        ## run "xinput" to get ID of your keyboard
        ## run "xinput --test <ID>" and hit Escape to check the Escape key is key[9] 
        keypress=$(xinput --query-state 16 | grep -c "key\[9\]=down")
        if [ "$keypress" == "1"  ]
        then
            escape_pause=$(($escape_pause + 1))
        else
            escape_pause=0
        fi
        sleep 0.1
    done
}


click_and_wait() {
    for num in $(seq $subset_start $total_loops)
    do
        if [ $num -le $subset_end ]
        then
            radius=10
            mod=$((radius + 1))
            this_x=$((${X_coords[$num]} + RANDOM % mod - radius / 2))
            this_y=$((${Y_coords[$num]} + RANDOM % mod - radius / 2))
            xdotool mousemove --sync "$this_x" "$this_y" click 1 > /dev/null
        else
            wmctrl -a $current_term
            remainder=$(echo "$loops_waited % $loops_per_second" | bc)
            if [ $remainder -eq 0 ]
            then
                if [ $loops_waited -eq 0 ]
                then
                    printf $delay
                else
                    printf $(($delay - $loops_waited / $loops_per_second))
                fi
            fi
            sleep $loop_sleep 
            loops_waited=$(($loops_waited + 1))
        fi

        if [ $escape -eq 10 ]
        then
            escape=0
            pause_until_keypress
            break
        fi

        ## run "xinput" to get ID of your keyboard
        ## run "xinput --test <ID>" and hit Escape to check the Escape key is key[9] 
        keypress=$(xinput --query-state 16 | grep -c "key\[9\]=down")
        if [ "$keypress" == "1"  ]
        then
            escape=$(($escape + 1))
        else
            escape=0
        fi
    done
}

auto_click() {
    escape=0
    loop_sleep=0.1
    loops_per_second=$(echo "1 / $loop_sleep" | bc)
    button_duration=1
    delay_loops=$(awk "BEGIN {print $delay / $loop_sleep}")
    total_loops=$(($delay_loops + $subset_end))
    while [ $run_no -gt  0 ]
    do
        run_no=$(($run_no - 1))
        declare -p repeats run_no delay X_coords Y_coords > $vars_path
        printf "\n"$run_no" "

        loops_waited=0
        click_and_wait
    done
}

add_locations() {
    ask_locations $1 $2
    X_coords=( "${X_coords[@]:0:$2}" "${X_return[@]}" "${X_coords[@]:$2}" )
    Y_coords=( "${Y_coords[@]:0:$2}" "${Y_return[@]}" "${Y_coords[@]:$2}" )
    declare -p repeats run_no delay X_coords Y_coords > $vars_path
}

parse_args() {
    PARAMS=""
    while (( "$#" )); do
      case "$1" in
        -n)
          number=$2
          ask_locations=true
          shift 2
          ;;
        -r)
          repeats=$2
          run_no=$repeats
          shift 2
          ;;
        -d)
          delay=$2
          shift 2
          ;;
        -o)
          onetime_variables=true
          shift
          ;;
        -m)
          minimise_terminal=true
          shift
          ;;
        -s)
          subset_start=$2
          subset_end=$3
          shift 3
          ;;
        -a)
          add_locations=true
          number_locations=$2
          position_locations=$3
          shift 3
          ;;
        --) # end argument parsing
          shift
          break
          ;;
        -*|--*=) # unsupported flags
          echo "Error: Unsupported flag $1" >&2
          exit 1
          ;;
        *) # preserve positional arguments
          PARAMS="$PARAMS $1"
          shift
          ;;
      esac
    done
    # set positional arguments in their proper place
    eval set -- "$PARAMS"

}

end_script() {
    if [ $minimise_terminal = true ]
    then
        resize -s 26 101 > /dev/null
        wmctrl -r $current_term -b remove,above > /dev/null
    fi
}

trap end_script EXIT

add_locations=false
ask_locations=false
onetime_variables=false
minimise_terminal=false
subset_start=0
subset_end=0

script_dir="${BASH_SOURCE%/*}/"

vars_path=$script_dir"vars"
source $vars_path

parse_args $@

current_term=$(xdotool getwindowfocus getwindowname)

if [ $minimise_terminal = true ]
then
    wmctrl -r $current_term -b remove,maximized_horz && wmctrl -r $current_term -b remove,maximized_vert && sleep 0.1 && resize -s 1 20 > /dev/null
    wmctrl -r $current_term -b add,above > /dev/null
fi

if [ $ask_locations = true ]
then
    ask_locations $number
    X_coords=()
    Y_coords=()
    X_coords=( "${X_return[@]}" )
    Y_coords=( "${Y_return[@]}" )
fi

if [ $subset_end -eq 0 ]
then
    subset_end=$((${#X_coords[@]} - 1))
fi

if [ $onetime_variables = false ]
then
    declare -p repeats run_no delay X_coords Y_coords > $vars_path
fi

if [ $add_locations = true ]
then
    add_locations $number_locations $position_locations
else
    auto_click
fi

