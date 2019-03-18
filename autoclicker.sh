#!/usr/bin/env bash
# hint: use "xdotool getmouselocation" to get values
## hold down Escape key to exit

#name=$1

get_max_run_i() {
    max_run_no=$(printf "%d\n" "${run_no[@]}" | sort -nr | head -n1)
    max_run_no_i=$(echo "${run_no[@]/$max_run_no//}" | cut -d/ -f1 | wc -w)
    echo $max_run_no_i
}

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
            group=${i_to_grp[$num]}
            group_run_no=${run_no[$group]}

            if [ $group_run_no -gt 0 ]
            then
                radius=5
                mod=$((radius + 1))
                this_x=$((${X_coords[$num]} + RANDOM % mod - radius / 2))
                this_y=$((${Y_coords[$num]} + RANDOM % mod - radius / 2))
                xdotool mousemove --sync "$this_x" "$this_y" click 1 > /dev/null
            fi
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

save_vars() {
    declare -p repeats i_to_grp run_no delay X_coords Y_coords > $vars_path
}

auto_click() {
    escape=0
    loop_sleep=0.1
    loops_per_second=$(echo "1 / $loop_sleep" | bc)
    button_duration=1
    delay_loops=$(awk "BEGIN {print $delay / $loop_sleep}")
    total_loops=$(($delay_loops + $subset_end))

    max_run_i=$(get_max_run_i)

    while [ ${run_no[$max_run_i]} -gt  0 ]
    do
        save_vars

        printf "\n$(echo ${run_no[@]}' ')"

        loops_waited=0
        click_and_wait

        for i in ${!run_no[@]}
        do
            if [ ${run_no[$i]} -gt 0 ]
            then
                let "run_no[i]-=1"
            fi
        done
    done
}

add_locations() {
    ask_locations $1 $2
    X_coords=( "${X_coords[@]:0:$2}" "${X_return[@]}" "${X_coords[@]:$2}" )
    Y_coords=( "${Y_coords[@]:0:$2}" "${Y_return[@]}" "${Y_coords[@]:$2}" )
    save_vars
}

parse_args() {
    PARAMS=""
    while (( "$#" )); do
      case "$1" in
        -g)
          shift 1
          ask_locations=true
          i_to_grp=()
          total_n=0
          i=1
          while [[ ${!i} =~ ^[0-9]+$ ]]
          do
              grp_n=${!i}
              let "total_n+=grp_n"
              grp=$((i - 1))
              for j in $(seq 1 $grp_n)
              do
                  i_to_grp+=($grp)
              done
              let "i+=1"
          done

          number=$total_n

          shift $((i - 1))
          ;;
        -r)
          shift 1
          run_no=()
          i=1
          while [[ ${!i} =~ ^[0-9]+$ ]]
          do
              grp_r=${!i}
              run_no+=($grp_r)
              let "i+=1"
          done

          groups=${#run_no[@]}
          if [ ${#groups[@]} -ne ${i_to_grp[-1]} ]
          then
              echo "number of digits in the -r arg must match number of digits in the -g arg"
              exit
          fi
          shift $i
          ;;
        -n)
          number=$2
          ask_locations=true
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
          minimise_terminal=false
          shift
          ;;
        -s)
          subset_start=$2
          subset_end=$3
          shift 3
          ;;
        -a)
          add_locations=true
          add_to_group=$2
          number_locations=$3
          position_locations=$4
          shift 4
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
        resize -s 1 80 > /dev/null
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
    wmctrl -r $current_term -e 0,67,27,-1,-1
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
    save_vars
fi

if [ $add_locations = true ]
then
    add_locations $number_locations $position_locations $group_add
else
    auto_click
fi

