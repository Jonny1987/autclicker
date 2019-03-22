#!/usr/bin/env bash
echo $BASH_VERSION
list=( "/tmp/tmp.uELMMTwcOP" \
       "/tmp/tmp.21yA8Ur5ue" \
       "/tmp/tmp.gdxjvtN7WG" \
       "/tmp/tmp.VnFqo5hWZB" \
       "/tmp/tmp.vC9LRVQ2S6" \
       "/tmp/tmp.kLUvamJeeR" \
       "/tmp/tmp.QB6IPoPIdA" \
       "/tmp/tmp.TwcMF3weYa" \
       "/tmp/tmp.xmJiXemAEE" \
       "/tmp/tmp.x5kdK5EFK4" \
       "/tmp/tmp.lYEutgg5dc" \
       "/tmp/tmp.7u1Fo1fkR3" \
       "/tmp/tmp.vnLDYAVrJz" \
       "/tmp/tmp.4VKvonFNL2" \
       "/tmp/tmp.fJy4Pyb0bY" \
       "/tmp/tmp.kHAmU9Axsp" \
       "/tmp/tmp.q4wgHjZnuB" \
       "/tmp/tmp.JkGGICbcQg" \
       "/tmp/tmp.qqRwQ6lWzS" \
       "/tmp/tmp.z7l8wTHnAe" \
       "/tmp/tmp.WFINX0teeu" \
       "/tmp/tmp.i0FMjSMkE6" \
       "/tmp/tmp.Itdxvneeee" \
       "/tmp/tmp.NyGsQDkZhu" \
       "/tmp/tmp.AIdvF2YYkp" \
       "/tmp/tmp.Im7Z9Av3h1" \
       "/tmp/tmp.7RRjhq2XoE" \
       "/tmp/tmp.rCdh6ohMM0" \
       "/tmp/tmp.n4O4u9YVDm" \
       "/tmp/tmp.mrKDOSAbgm" \
       "/tmp/tmp.t2Ge88x4rC" \
       "/tmp/tmp.5M8p5nqoHw" \
       "/tmp/tmp.0lQNq4eOPU" \
       "/tmp/tmp.1bI6orWHRm" \
       "/tmp/tmp.ijbNlTcQxD" \
       "/tmp/tmp.wkZQWugDQw" \
       "/tmp/tmp.NC5ol8Ij68" \
       "/tmp/tmp.Utims1uYSl" \
       "/tmp/tmp.tvkkBW7Y6K" \ )

list2=( "Cash: £0.03" \
        "Win: £0.00" \
        "Win: £0.00" \
        "£0.00" \
        ": £0.03" \
        "Cash: £0.03" \
        ": £0.03" \
        "Win: £0.00" \
        "Cash: £0.03" \
        "Cash: £0.03" \
        "Cash: £0.03" \
        "Win: £0.00" \
        "Win: £0.00" \
        "Win: £0.00" \
        "Cash: £0.03" \
        "Win: £0.00" \
        "Bet: £1.00"  \
        "Cash: £0.03" \
        "Cash: £0.03" \
        "Win: £0.00" \
        "Cash: £0.03" \
        ": £0.03" \
        ": £0.03" \
        "£0.03" \
        ": £0.03" \
        "£0.00" \
        ": £0.03" \
        ": £0.03" \
        "Cash: £0.03" \
        "Cash: £0.03" \
        "Bet: £1.00" \
        "Cash: £0.03" \
        "Cash: £0.03" \
        "Cash: £0.03" \
        "£0.00" \
        "Credits: £0.00" \
        "Credits: £0.00" \
        "Credits: £0.00" \
        "Credits: £0.00" ) 

total_true=0
total=${#list[@]}

get_words() {
    convert -resize 800% -threshold $2% -resample 300 -resize 50% $1 _.png
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
    for i in {33..40}
    do
        balance=$(get_balance $1 $i)
        if [ "$balance" != "" ]
        then
            echo $i
            echo $balance
            exit
        fi
    done
    echo ""
}


for i in "${!list[@]}"
do
    image=${list[$i]}.png
    expected="${list2[$i]}" 
    result=$(get_balance_iterate $image)
    echo image: $image
    echo result: $result
    echo expected: $expected
    if [ "$result" != "" ]
    then
        echo true
        let "total_true+=1"
    fi
    echo ""

done
echo $total_true
echo $total
score=$(awk "BEGIN {print $total_true / $total}")
echo score: $score
