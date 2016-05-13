#!/bin/zsh -f
# Purpose: Runs all di- scripts found in the same directory
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2016-05-13

NAME="$0:t:r"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

zmodload zsh/datetime

LOG="$HOME/Library/Logs/$NAME.log"

[[ -e "$LOG" ]] 	|| touch "$LOG"				# Create log file if needed 

function timestamp { strftime "%Y-%m-%d at %H:%M:%S" "$EPOCHSECONDS" }
function log { echo "$NAME [`timestamp`]: $@" | tee -a "$LOG" }

# chdir to the directory where this script is found 
cd "$0:h"

COUNT='0'

log "---------- STARTING AT `timestamp` ---------- "

for i in di-*sh
do

		# If the name of the script being run is not the same as the name of this script
		# then...
	if [ "$i" != "$0:t" ]
	then
		log "Running $i"

		((COUNT++))

		$i  2>&1 | tee -a "$LOG"
	fi 
done


echo "Last run at `timestamp` when $COUNT apps were checked." >| "$HOME/.$NAME.lastrun.log"

log "---------- FINISHED AT `timestamp` ---------- "

exit 0
#EOF
