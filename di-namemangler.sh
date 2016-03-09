#!/bin/zsh -f
# Download and install Name Mangler
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-09-28

NAME="$0:t:r"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi


INFO=($(curl -A Safari -sfL 'http://manytricks.com/namemangler/appcast.xml' | tr -s ' ' '\012' | egrep '^(url|sparkle:shortVersionString)=' | head -2 | awk -F'"' '//{print $2}'))

URL="$INFO[1]"

LATEST_VERSION="$INFO[2]"

INSTALL_TO="/Applications/Name Mangler.app"

INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo '3.0.0'`

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

FILENAME="$HOME/Downloads/NameMangler-$LATEST_VERSION.dmg"

echo "$NAME: Downloading $URL to $FILENAME"

	# server doesn't like curl 
curl -A Safari --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"


if [ -e "$INSTALL_TO" ]
then
		# Quit app, if running
	pgrep -xq "$INSTALL_TO:t:r" && osascript -e 'tell application "Name Mangler" to quit'

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"
fi


MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
		| fgrep -A 1 '<key>mount-point</key>' \
		| tail -1 \
		| sed 's#</string>.*##g ; s#.*<string>##g')

echo "$NAME: Installing $MNTPNT/$INSTALL_TO:t to $INSTALL_TO"

ditto -v "$MNTPNT/$INSTALL_TO:t" "$INSTALL_TO"

if (( $+commands[unmount.sh] ))
then

	unmount.sh "$MNTPNT"
else
	diskutil eject "$MNTPNT" 
fi



exit 0
#
#EOF
