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

XML_FEED="http://rogueamoeba.net/ping/versionCheck.cgi?format=sparkle&bundleid=com.rogueamoeba.audiohijack3&system=1011&platform=osx&arch=x86_64&version=21098000"

# sparkle:version= is the only version information in feed

LATEST_VERSION=`curl -sfL "$XML_FEED" | awk -F'"' '/sparkle:version=/{print $2}'`

	# If any of these are blank, we should not continue
if [ "$LATEST_VERSION" = "" -o "$XML_FEED" = "" ]
then
	echo "$NAME: Error: bad data received:
	LATEST_VERSION: $LATEST_VERSION
	XML_FEED: $XML_FEED
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

if (( $+commands[lynx] ))
then

	RELEASE_NOTES_URL="$XML_FEED"

	echo "$NAME: Release Notes for $INSTALL_TO:t:r:\n"

	curl -sfL "$RELEASE_NOTES_URL" \
	| sed '1,/<body>/d; /<\/body>/,$d' \
	| lynx -dump -nomargins -nonumbers -width=10000 -assume_charset=UTF-8 -pseudo_inlines -nolist -stdin

	echo "\nSouce: <${RELEASE_NOTES_URL}>"

fi


## 2018-07-10 this doesn't seem to work, so I'm just hard-coding in the URL in URL
# URL=`curl -sfL 'http://rogueamoeba.com/audiohijack/download.php' | awk -F'"' '/http.*zip/{print $2}'`
#
# if [[ "$URL" == "" ]]
# then
# 	echo "URL is empty"
# 	exit 1
# fi

URL="https://rogueamoeba.com/audiohijack/download/AudioHijack.zip"

FILENAME="$HOME/Downloads/AudioHijack-${LATEST_VERSION}.zip"

echo "$NAME: Downloading $URL\nto\n$FILENAME:"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

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
