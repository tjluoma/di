#!/bin/zsh
#
#	Author:		Timothy J. Luoma
#	Email:		luomat at gmail dot com
#	Date:		2011-10-26
#
#	Purpose: 	get VLC
#
#	URL:

NAME="$0:t"

zmodload zsh/datetime

TIME=$(strftime "%Y-%m-%d-at-%H.%M.%S" "$EPOCHSECONDS")

HOST=`hostname -s`
HOST="$HOST:l"

LOG="$HOME/Library/Logs/metalog/$NAME/$HOST/$TIME.log"

[[ -d "$LOG:h" ]] || mkdir -p "$LOG:h"
[[ -e "$LOG" ]]   || touch "$LOG"

function timestamp { strftime "%Y-%m-%d at %H:%M:%S" "$EPOCHSECONDS" }
function log { echo "$NAME [`timestamp`]: $@" | tee -a "$LOG" }

die ()
{
	echo "$NAME: $@"
	exit 1
}

URL='http://update.videolan.org/vlc/sparkle/vlc-intel64.xml'

INSTALL_TO="/Applications/VLC.app"

URL=`curl -sfL "$URL" | tr -s ' |\012' '\012' | fgrep 'url=' | tr '"' ' ' | awk '{print $NF}' | gsort --version-sort | tail -1`

LATEST_VERSION=`echo "$URL:t:r" | tr -dc '[0-9].'`

INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo 0`

autoload is-at-least

is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

if [ "$?" = "0" ]
then
	echo "$NAME: Up-To-Date (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"
	exit 0
fi

echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"


for TEST_DIR in \
	"/Volumes/Data/Websites/iusethis.luo.ma/vlc" \
	"/Volumes/Drobo2TB/MacMiniColo/Data/Websites/iusethis.luo.ma/vlc" \
	"$HOME/Downloads"
do
	if [ -d "$TEST_DIR" ]
	then
		export DIR="$TEST_DIR"
		break
	fi
done

FILENAME="$DIR/vlc-$LATEST_VERSION.dmg"

MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
			| fgrep -A 1 '<key>mount-point</key>' \
			| tail -1 \
			| sed 's#</string>.*##g ; s#.*<string>##g')

if [[ "$MNTPNT" == "" ]]
then
	echo "$NAME: MNTPNT is empty"
	exit 0
fi


if [[ -e "$INSTALL_TO" ]]
then
	mv -vf "$INSTALL_TO" "$HOME/.Trash/VLC.$INSTALLED_VERSION.app"
fi


ditto --noqtn -v "$MOUNTED" "$INSTALL_TO"


MAX_ATTEMPTS="10"

SECONDS_BETWEEN_ATTEMPTS="1"

	# strip away anything that isn't a 0-9 digit
SECONDS_BETWEEN_ATTEMPTS=$(echo "$SECONDS_BETWEEN_ATTEMPTS" | tr -dc '[0-9]')
MAX_ATTEMPTS=$(echo "$MAX_ATTEMPTS" | tr -dc '[0-9]')

	# initialize the counter
COUNT=0

	# NOTE this 'while' loop can be changed to something else
while [ -d "$MNTPNT" ]
do

		# increment counter (this is why we init to 0 not 1)
	((COUNT++))

		# check to see if we have exceeded maximum attempts
	if [ "$COUNT" -gt "$MAX_ATTEMPTS" ]
	then

		echo "$NAME: Exceeded $MAX_ATTEMPTS"

		exit 0
	fi

		# don't sleep the first time through the loop
	[[ "$COUNT" != "1" ]] && sleep ${SECONDS_BETWEEN_ATTEMPTS}

	# Do whatever you want to do in the 'while' loop here
	diskutil eject "$MNTPNT"

done




exit 0


