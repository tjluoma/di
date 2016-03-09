#!/bin/zsh
# Purpose: Download and install the latest version of Evernote
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2015-05-01

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

XML_URL='https://update.evernote.com/public/ENMacSMD/EvernoteMacUpdate.xml'

LATEST_VERSION=`curl -sfL "$XML_URL" | awk -F'=' '/sparkle:shortVersionString/{print $NF}' | head -1 | tr -dc '[0-9].'`

INSTALLED_VERSION=`defaults read /Applications/Evernote.app/Contents/Info CFBundleShortVersionString 2>/dev/null`

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

DL_URL=`curl -sfL "$XML_URL" | awk -F'"' '/url=/{print $2}' | head -1`

FILENAME="$HOME/Downloads/Evernote-$LATEST_VERSION.zip"

if [ "$HOST" = "mini.luo.ma" ]
then
	cd "$HOME/Sites/iusethis.luo.ma/evernote" || cd "$HOME/Downloads"
else

	if [ -d "$HOME/BitTorrent Sync/iusethis.luo.ma/evernote" ]
	then
		cd "$HOME/BitTorrent Sync/iusethis.luo.ma/evernote" || cd "$HOME/Downloads"
	else
		cd "$HOME/Downloads"
	fi
fi

REMOTE_SIZE=`curl -sfL "$XML_URL" | awk -F'"' '/length=/{print $4}' | head -1`

zmodload zsh/stat

if [ -e "$FILENAME" ]
then
	SIZE=$(zstat -L +size "$FILENAME")
else
	SIZE='0'
fi

	# Download it
while [ "$SIZE" -lt "$REMOTE_SIZE" ]
do
	curl --progress-bar --location --fail --output "$FILENAME" "$DL_URL"
	SIZE=$(zstat -L +size "$FILENAME")
done



if [ -e "$INSTALL_TO" ]
then
		# Quit app, if running
	pgrep -xq "Evernote" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "Evernote" to quit'

		# move installed version to trash 
	mv -vf "$INSTALL_TO" "$HOME/.Trash/Evernote.$INSTALLED_VERSION.app"
fi


	# Install it
ditto -v --noqtn -xk "$FILENAME" /Applications/



exit
#
#EOF
