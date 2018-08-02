#!/bin/zsh -f
# Purpose: Download and install Audio Hijack 3
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2015-01-20

NAME="$0:t:r"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

INSTALL_TO='/Applications/Audio Hijack.app'

zmodload zsh/datetime

function timestamp { strftime "%Y-%m-%d at %H:%M:%S" "$EPOCHSECONDS" }

URL="http://rogueamoeba.net/ping/versionCheck.cgi?format=sparkle&bundleid=com.rogueamoeba.audiohijack3&system=1011&platform=osx&arch=x86_64&version=21098000"

LATEST_VERSION=`curl -sfL "$URL" | awk -F'"' '/sparkle:version=/{print $2}'`

	# If any of these are blank, we should not continue
if [ "$LATEST_VERSION" = "" -o "$URL" = "" ]
then
	echo "$NAME: Error: bad data received:
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	"

	exit 1
fi


if [ -d "$INSTALL_TO" ]
then
	INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleVersion 2>/dev/null || echo 0`

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
fi


## 2018-07-10 this doesn't seem to work, so I'm just hard-coding in the URL in DL_URL
# DL_URL=`curl -sfL 'http://rogueamoeba.com/audiohijack/download.php' | awk -F'"' '/http.*zip/{print $2}'`
#
# if [[ "$DL_URL" == "" ]]
# then
# 	echo "DL_URL is empty"
# 	exit 1
# fi

DL_URL="https://rogueamoeba.com/audiohijack/download/AudioHijack.zip"

FILENAME="$HOME/Downloads/AudioHijack-${LATEST_VERSION}.zip"

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

EXIT="$?"

if [ "$EXIT" = "0" ]
then

	echo "$NAME: Installation of $INSTALL_TO successful"

else
	echo "$NAME: 'ditto' failed (\$EXIT = $EXIT)"

	exit 1
fi


exit 0
#
#EOF
