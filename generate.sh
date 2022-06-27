#!/usr/bin/env bash
# vim: set fenc=utf-8 ts=4 sw=4 sts=4 et :

set -ueo pipefail

generate(){
    local filename=$1
    local count=$2
    local announcement=$3
    tts=""
    until [ "${count}" -eq 0 ]; do
        tts="${tts}${announcement} "
        : $((count--))
    done

    docker-compose run --rm --user ${UID}:${UID} --volume "${PWD}/recordings":/recordings \
        talkingpet \
        tts /recordings/${filename} ${tts}
}

generate one        300 "one"
generate two        300 "two"
generate three      300 "three"
generate talkingpet 50  "I am a talking pet"
generate trunk      50  "I am a trunk"
generate line_1     50  "I am a line number one"
generate line_2     50  "I am a line number two"
