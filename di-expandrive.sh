#!/bin/zsh -f
# Purpose:
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2015-07-30

NAME="$0:t:r"

# Not http://updates.expandrive.com/apps/expandrive.xml

# XML_FEED="http://updates.expandrive.com/appcast/expandrive.xml?version=5"

XML_FEED="http://updates.expandrive.com/appcast/expandrive.xml?version=5"

LATEST_VERSION=`curl -sfL "$XML_FEED" | tr -s '[:blank:]' '\012' | awk -F'"' '/sparkle:version/{print $2}' | head -1`

INSTALLED_VERSION=`defaults read /Applications/ExpanDrive.app/Contents/Info CFBundleVersion`

autoload is-at-least

is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

if [ "$?" = "0" ]
then
	echo "$NAME: Up-To-Date (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"
	exit 0
fi

echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"


DL_URL=`curl -sfL "$XML_FEED" | tr -s '[:blank:]' '\012' | awk -F'"' '/url=/{print $2}' | head -1`

if [ -d '/Volumes/Data/Websites/iusethis.luo.ma/expandrive' ]
then
	DIR='/Volumes/Data/Websites/iusethis.luo.ma/expandrive'

	cd "$DIR"

	mkdir -p old

	mv -vn * old/ 2>/dev/null

else
	DIR="$HOME/Downloads"
fi

cd "$DIR"

FILENAME="$DIR/expandrive-$LATEST_VERSION.dmg"

echo "$NAME: Downloading $DL_URL to $FILENAME"

curl --progress-bar --continue-at - --fail --location --output  "$FILENAME" "$DL_URL"

while [ "`pgrep ExpanDrive`" != "" ]
do

	MSG="ExpanDrive is running. Please quit before proceeding."

	echo "$NAME: $MSG"

	if (is-growl-running-and-unpaused.sh)
	then

		growlnotify  \
		--appIcon "ExpanDrive" \
		--identifier "$NAME" \
		--message "$MSG" \
		--title "$NAME"

	fi

	sleep 30

done


MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
		| fgrep -A 1 '<key>mount-point</key>' \
		| tail -1 \
		| sed 's#</string>.*##g ; s#.*<string>##g')

## the App on the DMG is an installer which will move the old app aside and install the new one, then eject the DMG

open "$MNTPNT/ExpanDrive.app"


exit 0
#
#EOF
