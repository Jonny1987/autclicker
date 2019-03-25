#!/usr/bin/env bash
## hold down Escape key to exit

get_max_run_i() {
    max_run_no=$(printf "%d\n" "${run_no[@]}" | sort -nr | head -n1)
    max_run_no_i=$(echo "${run_no[@]/$max_run_no//}" | cut -d/ -f1 | wc -w)
    echo $max_run_no_i
}

get_grp_balance() {
    for i in {1..5}
    do
        group=$1
        maim -g ${bal_loc[$group]} balance_$group.png -m 10
        balance=$(./get_balance.sh balance_$group.png)

        if [ ! -z $balance ]
        then
            echo $balance
            return
        fi
        sleep 0.5
    done
    echo "Cannot get balance for group $group"
    exit
}

ask_balance_location() {
    group=$1
    echo "highlight balance area for group $group"
    for i in {1..10}
    do
        read -r bal_loc[$group] < <(slop -f "%g")
        xdotool mousemove_relative 1 1
        balance=$(get_grp_balance $group)

        if [ ! -z $balance ]
        then
            return
        fi
        echo "Please redo group $group"
    done
    exit 1
}

get_click_location() {
    until xinput --query-state $MOUSE | grep -c "button\[1\]=down" > /dev/null
    do
        :
    done
    eval "$(xdotool getmouselocation --shell)"
    until xinput --query-state $MOUSE | grep -c "button\[1\]=up" > /dev/null
    do
        :
    done
}

ask_window_icon_location() {
    group=$1
    echo "click on window icon for group $group"
    get_click_location
    icon_loc_x[$group]=$X
    icon_loc_y[$group]=$Y
}

ask_click_locations() {
    number_locations=$1
    X_return=()
    Y_return=()
    for num in $(seq 1 "$number_locations")
    do
        get_click_location
        X_return[$num]=$X
        Y_return[$num]=$Y
    done
}

ask_all_locations() {
    if [ $minimise_terminal = true ]
    then
        minimise_terminal 2
    fi

    X_coords=()
    Y_coords=()
    icon_log_x=()
    icon_log_y=()
    bal_loc=()

    for ((g=0; g<groups; ++g))
    do
        ask_window_icon_location $g
        ask_balance_location $g

        grp_n=${grp_ns[$g]}
        echo "Click on autoclick locations for group $group"
        ask_click_locations $grp_n

        X_coords+=(${X_return[@]})
        Y_coords+=(${Y_return[@]})
    done
}

minimise_terminal() {
    lines=$1
    wmctrl -r $current_term -b remove,maximized_horz && wmctrl -r $current_term -b remove,maximized_vert && sleep 0.1 && resize -s $lines 80 > /dev/null
    wmctrl -r $current_term -e 0,67,27,-1,-1
    wmctrl -r $current_term -b add,above > /dev/null
}

pause_until_keypress() {
    while true
    do
        sleep 0.1
        keypress=$(xinput --query-state $KEYBOARD | grep -c "key\[9\]=up")
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
        keypress=$(xinput --query-state $KEYBOARD | grep -c "key\[9\]=down")
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
    index=0
    for grp in ${!grp_ns[@]}
    do
        grp_n=${grp_ns[$grp]}

        xdotool mousemove --sync "${icon_loc_x[$grp]}" "${icon_loc_y[$grp]}" click 1 > /dev/null
        sleep 0.1
        
        for ((j=1; j<=$grp_n; ++j))
        do
            group_run_no=${run_no[$grp]}

            if [ $group_run_no -gt 0 ]
            then
                radius=5
                mod=$((radius + 1))
                this_x=$((${X_coords[$index]} + RANDOM % mod - radius / 2))
                this_y=$((${Y_coords[$index]} + RANDOM % mod - radius / 2))
                xdotool mousemove --sync "$this_x" "$this_y" click 1 > /dev/null
            fi
            let "index+=1"
        done

        sleep 0.5
        new_balances[$grp]=$(get_grp_balance $grp)

        if (( $( echo "${new_balances[$grp]} < ${balances[$grp]}" | bc -l) ))
        then
            if [ ${run_no[$grp]} -gt 0 ]
            then
                let "run_no[grp]-=1"
            fi
        fi
    done

    for ((i=1; i<=$delay_loops; ++i))
    do
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
    done

        if [ $escape -eq 10 ]
        then
            escape=0
            pause_until_keypress
            break
        fi

        ## run "xinput" to get ID of your keyboard
        ## run "xinput --test <ID>" and hit Escape to check the Escape key is key[9] 
        keypress=$(xinput --query-state $KEYBOARD | grep -c "key\[9\]=down")
        if [ "$keypress" == "1"  ]
        then
            escape=$(($escape + 1))
        else
            escape=0
        fi
}

save_vars() {
    declare -p icon_loc_x icon_loc_y bal_loc grp_ns run_no delay X_coords Y_coords > $vars_path
}

auto_click() {
    if [ $minimise_terminal = true ]
    then
        minimise_terminal 1
    fi

    escape=0
    loop_sleep=0.1
    loops_per_second=$(echo "1 / $loop_sleep" | bc)
    button_duration=1
    click_loops=$((${#X_coords[@]} - 1))
    delay_loops=$(awk "BEGIN {print $delay / $loop_sleep}")

    max_run_i=$(get_max_run_i)

    balances=() 

    groups=${#run_no[@]}
    for ((g=0; g<groups; ++g))
    do
        balances[$g]=$(get_grp_balance $g)
    done

    new_balances=()

    while [ ${run_no[$max_run_i]} -gt 0 ]
    do
        #save_vars
        printf "\n$(echo ${run_no[@]}' ')"

        loops_waited=0
        click_and_wait
    done
}

add_click_locations() {
    ask_click_locations $1
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
          ask_all_locations=true
          grp_ns=()
          total_n=0
          i=1
          while [[ ${!i} =~ ^[0-9]+$ ]]
          do
              grp_n=${!i}
              grp_ns+=($grp_n)
              let "total_n+=grp_n"
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
          if [ $groups -ne ${#grp_ns[@]} ]
          then
              echo "number of digits in the -r arg must match number of digits in the -g arg"
              exit
          fi
          shift $((i - 1))
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
        -a)
          add_click_locations=true
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

get_xinput_device() {
    device_name=$1
    xinput | grep -i $device_name | tail -1 | grep -oP "(?<=id=)[0-9]{1,2}"
}

trap end_script EXIT

MOUSE=$(get_xinput_device mouse)
KEYBOARD=$(get_xinput_device keyboard)

add_click_locations=false
ask_all_locations=false
onetime_variables=false
minimise_terminal=true

script_dir="${BASH_SOURCE%/*}/"

vars_path=$script_dir"vars"

if [ -f $vars_path ]
then
    source $vars_path
fi

parse_args $@

current_term=$(xdotool getwindowfocus getwindowname)

if [ $ask_all_locations = true ]
then
    ask_all_locations=false
    ask_all_locations
fi

if [ $onetime_variables = false ]
then
    save_vars
fi

if [ $add_click_locations = true ]
then
    add_click_locations $number_locations $position_locations $group_add
else
    auto_click
fi

