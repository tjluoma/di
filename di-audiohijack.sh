#!/bin/zsh
# Purpose: Download and install Audio Hijack 3
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2015-01-20

NAME="$0:t:r"

INSTALL_TO='/Applications/Audio Hijack.app'

zmodload zsh/datetime

TIME=$(strftime "%Y-%m-%d-at-%H.%M.%S" "$EPOCHSECONDS")

HOST=`hostname -s`
HOST="$HOST:l"

LOG="$HOME/Library/Logs/metalog/$NAME/$HOST/$TIME.log"

[[ -d "$LOG:h" ]] || mkdir -p "$LOG:h"
[[ -e "$LOG" ]]   || touch "$LOG"

function timestamp { strftime "%Y-%m-%d at %H:%M:%S" "$EPOCHSECONDS" }

function log { echo "$NAME [`timestamp`]: $@" | tee -a "$LOG" }


#DOWNLOAD_PAGE='http://rogueamoeba.com/audiohijack/download.php'

# http://neutral.rogueamoeba.com/mirror/files/AudioHijack.zip

# DL_URL=`curl -sfL "$DOWNLOAD_PAGE" | tr '"' '\012' | egrep -i "^http.*\.zip$"`

# http://rogueamoeba.net/ping/versionCheck.cgi?format=sparkle&bundleid=com.rogueamoeba.AudioHijackPro2&system=1092&platform=osx&arch=x86_64&version=21098000

# Everything should be pretty self-explanatory except the version numbering, which is based on Mac OS 9 (BCD) but has four digits tacked on for the "release type" -- 8000 are our publicly available releases, so you'll likely want to stick with that. If you're feeling particularly freaky, switch out the format from "sparkle" to "isis" and you'll have a plist to play with instead.

# 			<enclosure sparkle:version="3.2.1" url="http://rogueamoeba.com/audiohijack/download.php" type="application/octet-stream"/>

URL="http://rogueamoeba.net/ping/versionCheck.cgi?format=sparkle&bundleid=com.rogueamoeba.audiohijack3&system=1011&platform=osx&arch=x86_64&version=21098000"

LATEST_VERSION=`curl -sfL "$URL" | awk -F'"' '/sparkle:version=/{print $2}'`

if [ -d "$INSTALL_TO" ]
then
	INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleVersion 2>/dev/null || echo 0`
else
	INSTALLED_VERSION='0'
fi


autoload is-at-least

is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

if [ "$?" = "0" ]
then
	echo "$NAME: Up-To-Date (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"
	exit 0
fi

echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"

DL_URL=`curl -sfL 'http://rogueamoeba.com/audiohijack/download.php' | awk -F'"' '/http.*zip/{print $2}'`

if [[ "$DL_URL" == "" ]]
then
	log "DL_URL is empty"
	exit 0
fi

for TEST_DIR in \
	"/Volumes/Data/Websites/iusethis.luo.ma/audiohijack" \
	"/Volumes/Drobo2TB/MacMiniColo/Data/Websites/iusethis.luo.ma/audiohijack" \
	"$HOME/Downloads"
do
	if [ -d "$TEST_DIR" ]
	then
		export DIR="$TEST_DIR"
		break
	fi
done

FILENAME="$DIR/audiohijack-${LATEST_VERSION}.zip"

echo "$NAME: Downloading $DL_URL\nto\n$FILENAME:"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$DL_URL"


function get-pid { export PID=`pgrep -x 'Audio Hijack' || echo ` }

get-pid

while [ "$PID" != "" ]
do
	echo "$NAME: $INSTALL_TO:t is running (PID: $PID). Quit to continue. Sleeping 30 seconds from `timestamp`."
	sleep 30
	get-pid
done

if [[ -e "$INSTALL_TO" ]]
then
	mv -vn "$INSTALL_TO" "$HOME/.Trash/Audio Hijack.$INSTALLED_VERSION.app"
fi

ditto -xk -v --rsrc --extattr --noqtn "$FILENAME" "$INSTALL_TO:h"



exit 0
#
#EOF
