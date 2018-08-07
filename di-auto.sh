#!/bin/zsh -f
# Purpose: Checks all di-*.sh scripts in same directory to see if the corresponding apps are installed.
#
# From: 	Alister Forbes
# Mail:	di at superbimble dot com
# Date: 	2016-05-21
# Updated by TJ Luoma (luomat at gmail dot com) on 2018-08-06
#

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

log "------------- STARTING AT `timestamp` -------------"

for ARGS in "$@"
do
	case "$ARGS" in
		-u|--update)
				DI_UPDATE='yes'
				shift
		;;

		-*|--*)
				echo "	$NAME [warning]: Don't know what to do with arg: $1"
				shift
		;;
	esac
done # for args

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
			if [[ -e "$INSTALL_TO" ]]
			then

					# If you want to actually update the apps, not just check the list.
				((COUNT++))

				log "Running '$i'"

				"$i" 2>&1 | tee -a "$LOG"

			else
				## Uncomment the line below for more verbose output
				log "'$INSTALL_TO' is not installed (does not exist) on this computer."

			fi # if INSTALL_TO exists

		fi # if INSTALL_TO is empty

	fi # neither "di-all.sh nor di-auto.sh"
done

if [ "$COUNT" = "0" ]
then
	log "------------- FINISHED AT `timestamp` -------------"
else
	log "------------- FINISHED AT `timestamp`. Checked $COUNT apps for updates. -------------"
fi

if [[ "$DI_UPDATE" != "yes" ]]
then
	echo "$NAME: Use '$0 --update' to update apps using the corresponding di- script, but only for apps which are already installed."
fi



exit 0
