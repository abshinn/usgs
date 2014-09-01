#!/usr/bin/env bash
#
# query usgs web service with curl and print latest earthquakes greater than 2.5

howlong='day'
sortmag=false
helpmsg=false
verbose=false

while getopts 'Hshv' flag; do
  case "${flag}" in
    H) howlong='hour' ;;
    s) sortmag=true   ;;
    h) helpmsg=true   ;;
    v) verbose=true   ;;
    *) error "Unexpected option ${flag}" ;;
  esac
done

if $helpmsg; then
    echo NAME
    echo      quakes -- use curl to call usgs earthquake feed
    echo
    echo OPTIONS
    echo      -h    display this help message
    echo      -H    only show earthquakes in the past Hour, default is Day
    echo      -s    sort by magnitude, header removed 
    echo      -v    print feed url
    exit
fi

url='http://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/2.5_'
ext='.csv'

if $verbose; then
    echo $url$howlong$ext
fi

if $sortmag; 
    then curl -s $url$howlong$ext | sed 's/, / - /g' | cut -d, -f 1-5,14 | column -s, -t | tail +2 | sort -n -k 5,5 -r
    else curl -s $url$howlong$ext | sed 's/, / - /g' | cut -d, -f 1-5,14 | column -s, -t
fi
