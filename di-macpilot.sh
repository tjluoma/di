#!/bin/zsh
# Purpose:
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2015-10-27

NAME="$0:t:r"

INSTALL_TO='/Applications/MacPilot.app'

INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo 0`

OS_VER=`sw_vers -productVersion`

INFO=($(curl -sfL "http://www.koingosw.com/postback/versioncheck.php?appname=macpilot&appversion=${INSTALLED_VERSION}&sysplatform=Mac%20OS%20X&sysversion=Mac%20OS%20X%20${OS_VER}" \
| tr -s ' ' '\012' \
| egrep '^(url|sparkle:version)' \
| awk -F'"' '//{print $2}'))

URL="$INFO[1]"

LATEST_VERSION="$INFO[2]"

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


FILENAME="$HOME/Downloads/MacPilot-$LATEST_VERSION.dmg"

echo "$NAME: Downloading version $LATEST_VERSION to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
		| fgrep -A 1 '<key>mount-point</key>' \
		| tail -1 \
		| sed 's#</string>.*##g ; s#.*<string>##g')

if [[ "$MNTPNT" == "" ]]
then
	echo "$NAME: MNTPNT is empty"
	exit 0
fi


if [ -e "$INSTALL_TO" ]
then
		# Quit app, if running
	pgrep -xq "$INSTALL_TO:t:r" && osascript -e "tell application \"$INSTALL_TO:t:r\" to quit"

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"
fi


echo "$NAME: Installing $FILENAME to $INSTALL_TO"

ditto --noqtn "$MNTPNT/$INSTALL_TO:t" "$INSTALL_TO"

if (( $+commands[unmount.sh] ))
then

	unmount.sh "$MNTPNT"

else

	diskutil eject "$MNTPNT"

fi



exit 0
#
#EOF
