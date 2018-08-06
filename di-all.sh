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

EXPLAIN_USAGE='no'

LAUNCH_APPS='no'

	# Delete (old) log if it exists already
# [[ -e "$LOG" ]] 	|| rm -f "$LOG"

function timestamp { strftime "%Y-%m-%d at %-l:%M:%S %p" "$EPOCHSECONDS" }

function log { echo "$NAME [`timestamp`]: $@" | tee -a "$LOG" }

function launch_apps {

		# Show updates in the Mac App Store app:
	open 'macappstore://showUpdatesPage'

		# Check for common updaters:
	for APP in \
		'/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app' \
		'/Applications/MacUpdate Desktop.app' \
		'/Applications/MacUpdater.app'
	do
		EXPLAIN_USAGE='yes'

		echo "$NAME: Launching $APP:t"
		open -g -a "$APP:t"

	done
}

for ARGS in "$@"
do
	case "$ARGS" in
		-a|--all)
				LAUNCH_APPS='yes'
				shift
		;;

		-A|--apps)
					# JUST launch the GUI apps, don't run the di- scripts
				launch_apps

				echo "$NAME: Done!"

				exit 0
		;;

		-*|--*)
				echo "	$NAME [warning]: Don't know what to do with arg: $1"
				shift
		;;

	esac

done # for args

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

	"${line}" 2>&1 | tee -a "$LOG"

done

log "---------- FINISHED AT `timestamp` after checking $COUNT apps ---------- "

echo "$NAME last ran: `timestamp`. ${COUNT} apps were checked." >| "$HOME/.$NAME.lastrun.log"

if [[ "$LAUNCH_APPS" == 'yes' ]]
then
	launch_apps
else
		# Explain how to launch GUI updaters, if any are found.

	[[ "$EXPLAIN_USAGE" = "yes" ]] \
	&& echo "\n$NAME: use '$0 --apps' to _just_ launch updater apps,\n	or '$0 --all' to use both di- scripts _and_ GUI updaters. "
fi

exit 0
#EOF
