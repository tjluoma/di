#!/bin/zsh
# Purpose: Download and install latest BitTorrent Sync
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2014-10-11



INSTALL_TO="/Applications/BitTorrent Sync.app"



NAME="$0:t:r"

zmodload zsh/datetime

	# I cannot figure out where the '33685507' comes from
	# but I'll use it until it breaks
URL="http://update.getsync.com/cfu.php?cl=BitTorrent%20Sync&pl=osx&v=33685507&cmp=0&lang=en&sysver=10.11.0"


zmodload zsh/datetime

TIME=$(strftime "%Y-%m-%d-at-%H.%M.%S" "$EPOCHSECONDS")

HOST=`hostname -s`
HOST="$HOST:l"

LOG="$HOME/Library/Logs/metalog/$NAME/$HOST/$TIME.log"

[[ -d "$LOG:h" ]] || mkdir -p "$LOG:h"
[[ -e "$LOG" ]]   || touch "$LOG"

function timestamp { strftime "%Y-%m-%d at %H:%M:%S" "$EPOCHSECONDS" }
function log { echo "$NAME [`timestamp`]: $@" | tee -a "$LOG" }


TEMPFILE="${TMPDIR-/tmp}/${NAME}.${TIME}.$$.$RANDOM"


####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
#		Check to see what the latest version is
#

curl -sfL "$URL" \
| sed '1,/<item>/d; /<\/item>/,$d' \
| tr -s ' |\t' '\012' > "$TEMPFILE"

LATEST_VERSION=`awk -F'"' '/sparkle:version/{print $2}' "$TEMPFILE"`

URL=`awk -F'"' '/url/{print $2}' "$TEMPFILE"`

# EXPECTED_SIZE=`awk -F'"' '/length/{print $2}' "$TEMPFILE"`

# echo "
# $VERSION
# $URL
# $EXPECTED_SIZE
# $SIZE
# "

####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
#		Compare installed version with latest version
#

	# http://bashscripts.org/forum/viewtopic.php?f=16&t=1248

if [ -e "$INSTALL_TO" ]
then
	INSTALLED_VERSION=`defaults read $INSTALL_TO/Contents/Info CFBundleShortVersionString 2>/dev/null || echo 0`
else
	INSTALLED_VERSION='0'
fi

 if [[ "$LATEST_VERSION" == "$INSTALLED_VERSION" ]]
 then
 	echo "$NAME: Up-To-Date ($INSTALLED_VERSION)"
 	exit 0
 fi

autoload is-at-least

 is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"
 
 if [ "$?" = "0" ]
 then
 	echo "$NAME: Installed version ($INSTALLED_VERSION) is ahead of official version $LATEST_VERSION"
 	exit 0
 fi

echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"

####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
#		Set download directory
#


for TEST_DIR in \
	"$HOME/Sites/iusethis.luo.ma/bittorrentsync" \
	"/Volumes/Drobo2TB/MacMiniColo/Data/Websites/iusethis.luo.ma/bittorrentsync" \
	"$HOME/Downloads"
do
	if [ -d "$TEST_DIR" ]
	then
		export DIR="$TEST_DIR"
		break
	fi
done

####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
#		Download the latest version to a file with the version number in the name
#


FILENAME="$DIR/BitTorrentSync-${LATEST_VERSION}.dmg"

echo "$NAME: Downloading $URL\nto\n$FILENAME:"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"


#####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
#		Mount the DMG
#

MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
		| fgrep -A 1 '<key>mount-point</key>' \
		| tail -1 \
		| sed 's#</string>.*##g ; s#.*<string>##g')

if [[ "$MNTPNT" == "" ]]
then
	log "[FATAL] MNTPNT is empty"
	exit 0
fi

if [ ! -d "$MNTPNT" ]
then
	log "[FATAL] MNTPNT does not exist. This should not have happened."
	exit 0
fi

####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
#		Quit the app if it is running
#


while [[ "`pgrep 'BitTorrent Sync'`" != "" ]]
do

	log "Trying to quit "
	osascript -e 'tell application "BitTorrent Sync" to quit'

done

####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
#		If an old version of the app exists, move it to trash and show version number in filename
#

if [ -e "$INSTALL_TO" ]
then
	mv -vn "$INSTALL_TO" "$HOME/.Trash/BitTorrent Sync.$INSTALLED_VERSION.app"
fi

####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
#		Install the new version from the DMG (and then launch it)
#


ditto --noqtn -v "$MNTPNT/BitTorrent Sync.app" "$INSTALL_TO"

####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
#		Unmount the DMG
#

MAX_ATTEMPTS="10"
SECONDS_BETWEEN_ATTEMPTS="1"
COUNT=0

	# NOTE this 'while' loop can be changed to something else
while [ -d "$MNTPNT" ]
do
		# increment counter (this is why we init to 0 not 1)
	((COUNT++))

		# check to see if we have exceeded maximum attempts
	if [ "$COUNT" -gt "$MAX_ATTEMPTS" ]
	then
		log "Exceeded $MAX_ATTEMPTS"
		break
	fi

	[[ "$COUNT" != "1" ]] && sleep ${SECONDS_BETWEEN_ATTEMPTS} 	# don't sleep the first time through the loop

	# Do whatever you want to do in the 'while' loop here
	diskutil eject "$MNTPNT"
done


exit 0
#
#EOF
