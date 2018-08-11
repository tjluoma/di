#!/bin/zsh -f
# Purpose: Checks all di-*.sh scripts in same directory to see if the corresponding apps are installed.
#
# From: 	Alister Forbes
# Mail:	di at superbimble dot com
# Date: 	2016-05-21
# Updated by TJ Luoma (luomat at gmail dot com) on 2018-08-06
# See 'di-auto.txt' for details about significant changes to this script:
# https://github.com/tjluoma/di/blob/master/di-auto.txt

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin:./di-scripts'
fi

NAME="$0:t:r"

zmodload zsh/datetime

LOG="$HOME/Library/Logs/$NAME.log"

[[ -e "$LOG" ]]   || touch "$LOG"       # Create log file if needed

function timestamp { strftime "%Y-%m-%d at %H:%M:%S" "$EPOCHSECONDS" }
function log { echo "$NAME [`timestamp`]: $@" | tee -a "$LOG" }

# chdir to the directory where this script is found
cd "$0:h"

COUNT='0'
SKIP_COUNT='0'

log "------------- STARTING AT `timestamp` -------------"

for i in di-*sh
do
	#check to ignore di-all.sh and di-auto.sh
	if ! [[ "$i:t" =~  "di-(all|auto)\.sh" ]]
	then
			# get the full path to $i
		i=($i(:A))

		unset INSTALL_TO

		eval `egrep '^[	| ]*INSTALL_TO=' "$i" | egrep -v '^[	| ]*#' | tail -1`

		if [[ "$INSTALL_TO" == "" ]]
		then
			log "[ERROR!] No 'INSTALL_TO=' found in '$i'."
		else

				# If the app exists, put the script name in the list of installed apps
			if [[ -e "$INSTALL_TO" ]]
			then

					# If you want to actually update the apps, not just check the list.
				((COUNT++))

				[[ "$VERBOSE" == "yes" ]] && log "Running '$i'"

				"$i" 2>&1 | tee -a "$LOG"

			else
				## Uncomment the line below for more verbose output
				[[ "$VERBOSE" == "yes" ]] && log "'$INSTALL_TO' is not installed (does not exist) on this computer."

				((SKIP_COUNT++))

			fi # if INSTALL_TO exists

		fi # if INSTALL_TO is empty

	fi # neither "di-all.sh nor di-auto.sh"
done

log "Finished at `timestamp`. Checked $COUNT apps and skipped $SKIP_COUNT."

echo "Checked $COUNT apps at `timestamp`" >| "$HOME/.di-auto.lastrun.txt"

exit 0
