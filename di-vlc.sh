#!/bin/zsh -f
# Purpose: 	Download and install the latest version of VLC
#
#	Author:		Timothy J. Luoma
#	Email:		luomat at gmail dot com
#	Date:		2011-10-26
#
#
#	URL:

NAME="$0:t"

INSTALL_TO='/Applications/VLC.app'

XML_FEED='http://update.videolan.org/vlc/sparkle/vlc-intel64.xml'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

# NOTE: XML_FEED does not show 'sparkle:shortVersionString'

INFO=($(curl -sfL "$XML_FEED" \
	| tr ' ' '\012' \
	| egrep '^(url|sparkle:version)=' \
	| tail -2 \
	| sort \
	| awk -F'"' '//{print $2}'))

LATEST_VERSION="$INFO[1]"

URL="$INFO[2]"

if [ "$INFO" = "" -o "$LATEST_VERSION" = "" -o "$URL" = "" ]
then
	echo "$NAME: Bad data from $XML_FEED
	INFO: $INFO
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString`

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

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-$LATEST_VERSION.dmg"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && exit 0

MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
			| fgrep -A 1 '<key>mount-point</key>' \
			| tail -1 \
			| sed 's#</string>.*##g ; s#.*<string>##g')

if [[ "$MNTPNT" == "" ]]
then
	echo "$NAME: MNTPNT is empty"
	exit 0
else
	echo "$NAME: Mounted $FILENAME at $MNTPNT"
fi

if [[ -e "$INSTALL_TO" ]]
then
	mv -vf "$INSTALL_TO" "$HOME/.Trash/VLC.$INSTALLED_VERSION.app"
fi

echo "$NAME:  Installing $MNTPNT/VLC.app to $INSTALL_TO (this may take a few minutes)"

ditto --noqtn "$MNTPNT/VLC.app" "$INSTALL_TO"

EXIT="$?"

if [[ "$EXIT" == "0" ]]
then
	echo "$NAME: Installation of $INSTALL_TO was successful."
else
	echo "$NAME: Installation of $INSTALL_TO failed (\$EXIT = $EXIT)\nThe downloaded file can be found at $FILENAME."
fi

diskutil eject "$MNTPNT"

exit 0
