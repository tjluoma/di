#!/bin/zsh -f
# Purpose:
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2015-10-26

INSTALL_TO='/Applications/Feeder 3.app'

NAME="$0:t:r"

INFO=($(curl -sfL "https://reinventedsoftware.com/feeder/downloads/Feeder3.xml" \
| tr ' ' '\012' \
|sed 's#>#>\
#g' \
| egrep '^url="|^sparkle:shortVersionString' \
| head -2 \
| awk -F'"' '//{print $2}'))

URL="$INFO[1]"

LATEST_VERSION="$INFO[2]"

INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info"  CFBundleShortVersionString 2>/dev/null`

autoload is-at-least

is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

if [ "$?" = "0" ]
then
	echo "$NAME: Up-To-Date (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"
	exit 0
fi

echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"

FILENAME="$HOME/Downloads/$URL:t"

	# Download it
curl --continue-at - --fail --location --referer ";auto" --progress-bar --output "${FILENAME}" "$URL" 2>/dev/null

	# Mount the DMG
MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
		| fgrep -A 1 '<key>mount-point</key>' \
		| tail -1 \
		| sed 's#</string>.*##g ; s#.*<string>##g')

if [[ "$MNTPNT" == "" ]]
then
	echo "$NAME: MNTPNT is empty"
	exit 0
fi

	# Move the old version (if any) to trash
if [ -e "$INSTALL_TO" ]
then
	mv -vf "$INSTALL_TO" "$HOME/.Trash/Feeder 3.${INSTALLED_VERSION}.app"
fi

echo "$NAME: Installing $MNTPNT/$INSTALL_TO:t to $INSTALL_TO..."

	# Install it
ditto -v --noqtn "$MNTPNT/$INSTALL_TO:t" "$INSTALL_TO"

	# Eject the DMG
if (( $+commands[unmount.sh] ))
then
	unmount.sh "$MNTPNT"
else
	diskutil eject "$MNTPNT"
fi


exit 0
#
#EOF
