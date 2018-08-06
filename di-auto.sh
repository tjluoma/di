#!/bin/zsh -f
# Purpose: Runs all di- scripts found in the same directory
#
# From: Alister Forbes
# Mail:di at superbimble dot com
# Date: 2016-05-21
# Updated by TJ Luoma (luomat at gmail dot com) on 2018-08-06

NAME="$0:t:r"

	# Change this if you want the cache stored somewhere else, or under another name
DI_LIST="$HOME/.di.lst"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin:./di-scripts'
fi

zmodload zsh/datetime

[[ -e "$DI_LIST" ]] || touch "$DI_LIST"  # Create the list of installed software

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
	if ! [[ "$i:t" =~  "di-(all|auto)\.sh" ]]
	then
			# get the full path to $i
		i=($i(:A))


		#Check if the INSTALL_TO exists.  If it does, add it to the list
		# This FAILS for Evernote and hazel
		#LOC=`grep -m1 INSTALL_TO $i`

		# TJL added:
		# if there are multiple INSTALL_TO= lines, just get the last one'
		# in case the variable gets re-assigned during the script.
		# This will fail if INSTALL_TO= includes some kind of variable from the 'di-' script
		# which we obviously won't have access to here (that it what caused previous problems when
		# some scripts were using 'APPNAME=' instead of 'INSTALL_TO:t:r')
		#
		# ignore lines that start with '#' (after any optional tabs/spaces)
		# since those are just comments

		# Alister had previously commented:
		# "There must be a better way to do this.  We split on the = and then use rev to flip the string"
		# He was referring to this line:
		#LOCATION=$(echo "$LOC" | cut -d'=' -f2 | cut -c 2- | rev | cut -c 2- | rev)
		##
		## I'm not 100% sure what this was supposed to do, but it appears that it is
		## trying to get the value of '$LOCATION' without the '$INSTALL_TO=' part
		## The problem is that it won't expand variables such as "$HOME"
		## which is why it fails for a few scripts, most notably preference panes
		## such as Hazel and Witch, as they are most often installed to "$HOME/Library/PreferencePanes"
		##
		## I think the solution is that we need to use 'eval'.
		## Now I just need to get the syntax right. 'eval' always trips me up for some reason.

		unset INSTALL_TO

		eval `egrep '^[	| ]*INSTALL_TO=' "$i" | egrep -v '^[	| ]*#' | tail -1`

		if [[ "$INSTALL_TO" == "" ]]
		then
			echo "$NAME: No 'INSTALL_TO=' found in '$i'."
		else

			# If the app exists, put the script name in the list of installed apps
			if [ -e "$INSTALL_TO" ]
			then
				#  Check whether the App is already in the list
				if (egrep -qi "^${i}$" "$DI_LIST")
				then
					log "'$i' already stored in $DI_LIST"

				else
						# We got the full path to "$i" above
						# see the 'i=($i(:A))' line
						# so we can launch each of these scripts directly from that list if we need to
						# just by doing 'source "$DI_LIST"'

					echo "$i" >> "$DI_LIST"

					log "Found '$INSTALL_TO', so added '$i:t' to '$DI_LIST'."
				fi
			else

				log "'$INSTALL_TO' is not installed (does not exist) on this computer."

			fi # if INSTALL_TO exists

		fi # if INSTALL_TO is empty

	fi # neither "di-all.sh nor di-auto.sh"
done

log "------------- FINISHED AT `timestamp` -------------"

exit 0
