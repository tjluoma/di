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

	# Delete (old) log if it exists already
[[ -e "$LOG" ]] 	|| rm -f "$LOG"

function timestamp { strftime "%Y-%m-%d at %-l:%M:%S %p" "$EPOCHSECONDS" }

function log { echo "$NAME [`timestamp`]: $@" | tee -a "$LOG" }

# chdir to the directory where this script is found
cd "$0:h"

COUNT='0'

log "---------- STARTING AT `timestamp` ---------- "


##
## Get a list of all of the 'di-*.sh' files (be sure to exclude this script (di-all.sh) or else it'll go on forever)
##

command ls -1 di-*sh \
| egrep -v '(di-all.sh|di-auto.sh)' \
| while read line
do

	log "Running $line"

	((COUNT++))

	"${line}"  2>&1 | tee -a "$LOG"

done

log "---------- FINISHED AT `timestamp` after checking $COUNT apps ---------- "

echo "$NAME last ran: `timestamp`. ${COUNT} apps were checked." >| "$HOME/.$NAME.lastrun.log"

exit 0
#EOF
