#!/bin/zsh -f
# Purpose: 	Checks all di-*.sh scripts in same directory to see if the corresponding apps are installed.
#
# From: 	Alister Forbes
# Mail:		di at superbimble dot com
# Date: 	2016-05-21
#
# Updated by TJ Luoma (luomat at gmail dot com) on 2018-08-06
#
# See 'di-auto.txt' for details about significant changes to this script:
# https://github.com/tjluoma/di/blob/master/di-auto.txt

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

NAME="$0:t:r"

zmodload zsh/datetime

LOG="$HOME/Library/Logs/$NAME.log"

[[ -e "$LOG" ]]   || touch "$LOG"       # Create log file if needed

function timestamp { strftime "%Y-%m-%d at %H:%M:%S" "$EPOCHSECONDS" }
function log { echo "$NAME [`timestamp`]: $@" | tee -a "$LOG" }

# chdir to the directory where this script is found
cd "$0:h"

log "------------- STARTING AT `timestamp` -------------"

for i in di-*sh
do
	#check to ignore di-all.sh and di-auto.sh
	if ! [[ "$i:t" =~ "di-(all|auto)\.sh" ]]
	then
			# get the full path to $i
		i=($i(:A))

		unset INSTALL_TO

		IFS=$'\n' ALL_INSTALLS=($(fgrep 'INSTALL_TO=' "$i" | fgrep -v '#' | fgrep -v 'INSTALL_TO="$'))

		if [[ "$ALL_INSTALLS" == "" ]]
		then
			IFS=$'\n' ALL_INSTALLS=($(fgrep 'INSTALL_TO=' "$i" | fgrep -v '#'))
		fi

		if [[ "$ALL_INSTALLS" == "" ]]
		then
				log "[ERROR!] No 'INSTALL_TO=' found in '$i'."
		else
			echo "$ALL_INSTALLS" | while read line
			do
				unset INSTALL_TO

				eval $line

				if [[ "$INSTALL_TO" != "" ]]
				then

					if [[ -e "$INSTALL_TO" ]]
					then

						[[ "$VERBOSE" == "yes" ]] && log "Running '$i'"

						"$i" 2>&1 | tee -a "$LOG"

					else

						## Uncomment the line below for more verbose output
						[[ "$VERBOSE" == "yes" ]] && log "'$INSTALL_TO' is not installed (does not exist) on this computer."

					fi # if INSTALL_TO exists

				fi

			done
		fi

	fi # neither "di-all.sh nor di-auto.sh"
done

log "Finished at `timestamp`."

echo "Last run was at `timestamp`" >| "$HOME/.di-auto.lastrun.txt"

if (( $+commands[di-local.sh] ))
then
		# if the command 'di-local.sh' is found in $PATH, run it.
		# This is intended to allow users to have their own 'di-'
		# scripts which are not part of the official repo
		# but which are triggered as part of 'di-auto.sh'
	echo "$NAME: Found 'di-local.sh'. Running it:"

	di-local.sh

fi

exit 0
