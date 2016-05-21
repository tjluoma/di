#!/bin/zsh
# Download and install latest LaunchControl
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-05-26

NAME="$0:t:r"

zmodload zsh/datetime

TIME=$(strftime "%Y-%m-%d-at-%H.%M.%S" "$EPOCHSECONDS")

HOST=`hostname -s`
HOST="$HOST:l"

LOG="$HOME/Library/Logs/metalog/$NAME/$HOST/$TIME.log"

[[ -d "$LOG:h" ]] || mkdir -p "$LOG:h"
[[ -e "$LOG" ]]   || touch "$LOG"

function timestamp { strftime "%Y-%m-%d at %H:%M:%S" "$EPOCHSECONDS" }
function log { echo "$NAME [`timestamp`]: $@" | tee -a "$LOG" }

XML_URL='http://www.soma-zone.com/LaunchControl/a/appcast_update.xml'

DOWNLOAD_URL=`curl -sfL "$XML_URL" \
| tr '[:blank:]' '\012' \
| egrep '^url' \
| tail -1 \
| sed 's#url="##g ; s#"$##g'`

DL_SIZE=`curl -sfL "$XML_URL" \
| tr '[:blank:]' '\012' \
| egrep '^length' \
| tail -1 \
| tr -dc '[0-9]'`

LATEST_VERSION=`curl -sfL "$XML_URL" \
| tr '[:blank:]' '\012' \
| egrep '^sparkle:shortVersionString=' \
| tail -1 \
| tr -dc '[0-9].'`

INSTALLED_VERSION=`defaults read /Applications/LaunchControl.app/Contents/Info CFBundleShortVersionString 2>/dev/null || echo '0'`

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


log "Update needed $LATEST_VERSION vs $INSTALLED_VERSION"

cd "$HOME/Sites/iusethis.luo.ma/launchcontrol" 2>/dev/null \
	|| cd '/Volumes/Drobo2TB/BitTorrent Sync/iusethis.luo.ma/launchcontrol' 2>/dev/null \
	|| cd "$HOME/BitTorrent Sync/iusethis.luo.ma/launchcontrol" 2>/dev/null \
	|| cd "$HOME/Downloads/" 2>/dev/null \
	|| cd "$HOME/"

if [ -d old ]
then
	mv *.tar.bz2 old/
fi

FILENAME="$HOME/Downloads/LaunchControl-$LATEST_VERSION.tar.bz2"

zmodload zsh/stat

SIZE=$(zstat -L +size "$FILENAME" || echo '0')

if [ "$SIZE" -lt "$DL_SIZE" ]
then
	curl -fL --progress-bar --output "$FILENAME" "$DOWNLOAD_URL"
fi

SIZE=$(zstat -L +size "$FILENAME" 2>/dev/null || echo '0')

if [ "$SIZE" -lt "$DL_SIZE" ]
then
	log "Size mismatch: Actual $SIZE vs expected $DL_SIZE"
	exit 0
fi

if [ -e /Applications/LaunchControl.app ]
then
	mv -vn /Applications/LaunchControl.app "$HOME/.Trash/LaunchControl-$INSTALLED_VERSION.app"
fi

if [ -e /Applications/LaunchControl.app ]
then
	log "Failed to remove old /Applications/LaunchControl.app"
	exit 0
fi

	# Unpack and Install the .tar.bz2 file to /Applications/
tar -C "/Applications/" -j -x -f "$FILENAME"

exit 0
#
#EOF
