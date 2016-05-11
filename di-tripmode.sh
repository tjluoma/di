#!/bin/zsh -f
# Purpose: 
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2016-05-10

NAME="$0:t:r"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

zmodload zsh/datetime

TIME=$(strftime "%Y-%m-%d-at-%H.%M.%S" "$EPOCHSECONDS")

HOST=`hostname -s`
HOST="$HOST:l"

LOG="$HOME/Library/Logs/$NAME.$HOST.$TIME.log"

[[ -d "$LOG:h" ]] || mkdir -p "$LOG:h"
[[ -e "$LOG" ]] || touch "$LOG"

function timestamp { strftime "%Y-%m-%d at %H:%M:%S" "$EPOCHSECONDS" }

function log { echo "$NAME [`timestamp`]: $@" | tee -a "$LOG" }

if [ -e  /Applications/TripMode.app ]
then
	echo "$NAME: TripMode.app is already installed."
	exit 0
fi 

cd $HOME/Downloads
	
curl --location --fail https://tripmode.ch/TripMode.pkg

sudo installer -pkg "TripMode.pkg" -target / -lang en 2>&1 | tee -a "$LOG"


exit 0


# @TODO - Add update not just install? Need to find XML feed for updates. Charles?


#EOF
