#!/bin/zsh -f
# Purpose: Runs all di- scripts found in the same directory
#
# From: Alister Forbes
# Mail:di at superbimble dot com
# Date: 2016-05-21

# add something to sort out the path
NAME="$0:t:r"

if [ -e "$HOME/.path" ]
then
  source "$HOME/.path"
else
  PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin:./di-scripts'
fi

zmodload zsh/datetime

LOG="$HOME/Library/Logs/$NAME.log"
[[ -e "$LOG" ]]   || touch "$LOG"       # Create log file if needed

function timestamp { strftime "%Y-%m-%d at %H:%M:%S" "$EPOCHSECONDS" }
function log { echo "$NAME [`timestamp`]: $@" | tee -a "$LOG" }

log "------------- STARTING AT `timestamp` -------------"

[[  -e "./di-scripts/di.lst" ]] || touch "./di-scripts/di.lst"  # Create the list of installed software
for i in di-scripts/di-*sh
do
    #Check if the INSTALL_TO exists.  If it does, add it to the list
    # This FAILS for Evernote and hazel

    LOC=`grep -m1 INSTALL_TO $i`
    
    # There must be a better way to do this.  We split on the = and then use rev to flip the string
    LOCATION=$(echo "$LOC" | cut -d'=' -f2 | cut -c 2- | rev | cut -c 2- | rev)

    # If the app exists, put the script name in the list of installed apps
    #  Actually we test for the app not existing, and then add the name if it fails.
    [[ ! -e "$LOCATION" ]] || echo $i >> ./di-scripts/di.lst
done

log "------------- FINISHED AT `timestamp` -------------"
