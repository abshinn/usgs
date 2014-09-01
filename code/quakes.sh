#!/usr/bin/env bash
#
# query usgs web service with curl and print latest earthquakes greater than 2.5

howlong='day'
sortmag=false

while getopts 'Hs' flag; do
  case "${flag}" in
    H) howlong='hour' ;;
    s) sortmag=true   ;;
    *) error "Unexpected option ${flag}" ;;
  esac
done

url='http://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/2.5_'
ext='.csv'

if $sortmag; 
    then curl -s $url$howlong$ext | sed 's/, / - /g' | cut -d, -f 1-5,14 | column -s, -t | tail +2 | sort -n -k5,5 -r
    else curl -s $url$howlong$ext | sed 's/, / - /g' | cut -d, -f 1-5,14 | column -s, -t
fi
