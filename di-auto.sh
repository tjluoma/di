#!/bin/zsh -f
# Purpose: Runs all di- scripts found in the same directory
#
# From: Alister Forbes
# Mail:di at superbimble dot com
# Date: 2016-05-21
# Updated by TJ Luoma (luomat at gmail dot com) on 2018-08-06

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

DI_LIST="$HOME/.di.lst"

function timestamp { strftime "%Y-%m-%d at %H:%M:%S" "$EPOCHSECONDS" }
function log { echo "$NAME [`timestamp`]: $@" | tee -a "$LOG" }

# chdir to the directory where this script is found
cd "$0:h"

log "------------- STARTING AT `timestamp` -------------"

[[ -e "$DI_LIST" ]] || touch "$DI_LIST"  # Create the list of installed software

for i in di-*sh
do
    #check to ignote di-all.sh and di-auto.sh
    if ! [[ "$i:t" =~  "di-(all|auto)\.sh" ]]
    then
      #Check if the INSTALL_TO exists.  If it does, add it to the list
      # This FAILS for Evernote and hazel

      LOC=`grep -m1 INSTALL_TO $i`

      # There must be a better way to do this.  We split on the = and then use rev to flip the string
      LOCATION=$(echo "$LOC" | cut -d'=' -f2 | cut -c 2- | rev | cut -c 2- | rev)

      # If the app exists, put the script name in the list of installed apps
      if [ -e "$LOCATION" ]
      then
        #  Check whether the App is already in the list
        if (grep "$i" "$DI_LIST")
        then
          log "  $LOCATION already stored"
        else
          echo $i >> "$DI_LIST"
          log "  $LOCATION added"
        fi
      fi
    fi
done

log "------------- FINISHED AT `timestamp` -------------"
