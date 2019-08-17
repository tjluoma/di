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

function timestamp { strftime "%Y-%m-%d @ %H:%M:%S" "$EPOCHSECONDS" }

LASTRUN="$HOME/.$NAME.lastrun.txt"

if [[ "$1" != "--force" ]]
then

	LASTRUN_TIME=$(tail "$LASTRUN" | egrep '[0-9]' | tail -1 | awk '{print $1}')

	DIFF=$(($EPOCHSECONDS - $LASTRUN_TIME))

		# unless "forced" don't run if we've run in the last 59 minutes
	if [ "$DIFF" -lt "3540" ]
	then

		TIME_AGO_READABLE=$(seconds2readable.sh "$DIFF")

		growlnotify  \
			--appIcon "iTerm" \
			--identifier "$NAME" \
			--message "${TIME_AGO_READABLE} ago" \
			--title "$NAME not running.
					Last ran: "

		po.sh "$NAME not running. Ran $TIME_AGO_READABLE ago."

		exit 0
	fi
fi

DATE=`strftime "%Y-%m-%d" "$EPOCHSECONDS"`

LOG="$HOME/Library/Logs/$NAME.$DATE.log"

[[ -e "$LOG" ]]   || touch "$LOG"       # Create log file if needed

function log { echo "$NAME [`timestamp`]: $@" | tee -a "$LOG" }

LOCKFILE="$HOME/.$NAME.lock"

if [[ -e "$LOCKFILE" ]]
then

	LOCKED_TIME=$(cat "$LOCKFILE" | sed 's#.* -- ##g')

	growlnotify \
		--appIcon "iTerm" \
		--identifier "$NAME LOCKFILE" \
		--message "Locked since
$LOCKED_TIME" \
		--title "$NAME: found LOCKFILE"

	echo "$NAME: Lockfile found at ${LOCKFILE}. Locked since ${LOCKED_TIME}. Exiting."

	po.sh "$NAME: Locked since $LOCKED_TIME"

	exit 0

else

	START_TIME="$EPOCHSECONDS"

	echo "$EPOCHSECONDS ($$) -- `timestamp`" >| "$LOCKFILE"

	echo "$EPOCHSECONDS	`timestamp`" >>| "$LASTRUN"

fi

COUNT=0

# chdir to the directory where this script is found
cd "$0:h"

log "------------- STARTING AT `timestamp` -------------"

for i in di-*sh
do
	#check to ignore di-all.sh and di-auto.sh
	if ! [[ "$i:t" =~ "di-(all|auto)\.sh" ]]
	then
		# echo "\n\n---: [Debug] Starting $i: \n"

			# get the full path to $i
		i=($i(:A))

		unset INSTALL_TO

		IFS=$'\n' ALL_INSTALLS=($(fgrep 'INSTALL_TO=' "$i" | fgrep -v '#' | fgrep -v 'INSTALL_TO="$' | sort -u))

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

						EXIT="$?"

						if [[ "$EXIT" != "0" ]]
						then

							growlnotify --sticky \
								--appIcon "$INSTALL_TO:t:r" \
								--identifier "$i" \
								--message "Exit With Error: $EXIT" \
								--title "$i"

							((COUNT++))

						fi

					else

						## Uncomment the line below for more verbose output
						[[ "$VERBOSE" == "yes" ]] && log "'$INSTALL_TO' is not installed (does not exist) on this computer."

					fi # if INSTALL_TO exists

				fi

			done
		fi

	fi # neither "di-all.sh nor di-auto.sh"
done

END_TIME="$EPOCHSECONDS"

DIFF=$(($END_TIME - $START_TIME))

if (( $+commands[seconds2readable.sh] ))
then
	ELAPSED_TIME=$(seconds2readable.sh "$DIFF")
else
	ELAPSED_TIME="$DIFF seconds"
fi

log "Finished. ${ELAPSED_TIME}. Error count is ${COUNT}."

if [[ "$COUNT" != "0" ]]
then

	growlnotify --sticky \
		--appIcon "Console" \
		--identifier "di-auto-errors" \
		--message "$ELAPSED_TIME" \
		--title "$NAME: With Errors ($COUNT)"

	open -g -j -a Console "$LOG"

else

	growlnotify \
		--appIcon "Console" \
		--identifier "di-auto-errors" \
		--message "$ELAPSED_TIME" \
		--title "$NAME: No Errors"

fi

if (( $+commands[di-local.sh] ))
then
		# if the command 'di-local.sh' is found in $PATH, run it.
		# This is intended to allow users to have their own 'di-'
		# scripts which are not part of the official repo
		# but which are triggered as part of 'di-auto.sh'
	log "Found 'di-local.sh'. Running it"

	di-local.sh

fi

rm -f "$LOCKFILE"

exit 0
