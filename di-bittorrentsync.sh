#!/bin/zsh -f
# Purpose: Download and install latest BitTorrent Sync (aka Resilio Sync)
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2014-10-11

	# 2018-08-02 - this is what the newest version available calls itself
INSTALL_TO='/Applications/BitTorrent Sync.app'


if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

NAME="$0:t:r"

zmodload zsh/datetime

	# I cannot figure out where the '33685507' comes from
	# but I'll use it until it breaks
URL="http://update.getsync.com/cfu.php?cl=BitTorrent%20Sync&pl=osx&v=33685507&cmp=0&lang=en&sysver=10.11.0"

zmodload zsh/datetime

LOG="$HOME/Library/Logs/${NAME}.log"

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

	# If any of these are blank, we should not continue
if [ "$LATEST_VERSION" = "" -o "$URL" = "" ]
then
	echo "$NAME: Error: bad data received:
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	"

	exit 1
fi

####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
#		Compare installed version with latest version
#

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

####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
#		Download the latest version to a file with the version number in the name
#

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}.dmg"

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

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

while [[ "`pgrep $INSTALL_TO:t:r`" != "" ]]
do

	log "Trying to quit "
	osascript -e 'tell application "$INSTALL_TO:t:r" to quit'
	LAUNCH='yes'

done

####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
#		If an old version of the app exists, move it to trash and show version number in filename
#

if [ -e "$INSTALL_TO" ]
then
	mv -vn "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"
fi

####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
#		Install the new version from the DMG (and then launch it if it was running previously)
#

echo "$NAME: Installing '$MNTPNT/$INSTALL_TO:t' to '$INSTALL_TO': "

ditto --noqtn -v "$MNTPNT/$INSTALL_TO:t" "$INSTALL_TO"

EXIT="$?"

if [[ "$EXIT" != "0" ]]
then
	echo "$NAME: ditto failed"

	exit 1
fi

echo "$NAME: Installation successful. Ejecting $MNTPNT:"

diskutil eject "$MNTPNT"

[[ "$LAUNCH" == "yes" ]] && open -a "$INSTALL_TO"

exit 0
#
#EOF
