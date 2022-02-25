#!/bin/sh

url="https://brett.fick.es/api"

play() {
    curl -s "${url}/play" \
        -H 'Content-Type: application/json' \
        --data "{\"group\":\"$group\",\"sound\":\"$sound\"}" \
        > /dev/null &
}

play_stop() {
    curl -s "${url}/stop" --data '' > /dev/null &
}

play_selection()
{
    group=$(echo "$1" | cut -f 1 -d '/');
    sound=$(echo "$1" | cut -f 2 -d '/');
    play "$group" "$sound"
}

if [ $# -eq 1 ] && [ $1 == '-s' ]; then
    play_stop
    exit
fi

if [ $# -gt 1 ] && [ $1 == '-e' ]; then
    shift
    play_selection "$@"
    exit
fi

if [ $# -eq 1 ] && [ $1 == '-p' ]; then
    persist=1
    shift
else
    persist=0
fi


if [ $# -eq 2 ]; then
    group=$1;
    sound=$2;

    play "$group" "$sound"
else
    if [ $# -eq 1 ]; then
        query="-q $1"
    else
        query=''
    fi

    fzf_cmd="fzf ${query}"

    if [ $persist -eq 1 ]; then
        curl -s "$url/sounds" |
            jq -r '.[] | .name + "/" + .sounds[].name' |
            $fzf_cmd --bind "enter:execute-silent(${BASH_SOURCE[0]} -e {}),ctrl-s:execute-silent(${BASH_SOURCE[0]} -s),esc:clear-query";

    else
        selection=$(curl -s $url/sounds |
            jq -r '.[] | .name + "/" + .sounds[].name' |
            $fzf_cmd --bind "ctrl-s:execute-silent(${BASH_SOURCE[0]} -s),esc:clear-query");

        play_selection "$selection"
    fi
fi
