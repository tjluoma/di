#!/bin/zsh -f
# Purpose: Download and install the latest version of Screens Connect
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-07-17

NAME="$0:t:r"

INSTALL_TO='/Applications/Screens Connect.app'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

# @TODO - sparkle:version= is also in the feed and _may_ be the better field to check? Both seem to be incremented whenever there is an update

XML_FEED="https://updates.devmate.com/com.edovia.Screens-Connect.xml"

## 2018-07-17 - the XML_FEED has a lot of entries in it, but the newest one is on top, and all the info is in one line.
## If that changes in the future, this script will break.

INFO=($(curl -sfL $XML_FEED \
		| egrep '<enclosure url="https://.*/ScreensConnect-.*.zip"' \
		| head -1 \
		| tr -s ' ' '\012' \
		| egrep 'sparkle:shortVersionString=|url=' \
		| sort \
		| awk -F'"' '/^/{print $2}'))

	# "Sparkle" will always come before "url" because of "sort"
LATEST_VERSION="$INFO[1]"

URL="$INFO[2]"

if [ "$URL" = "" -o "$LATEST_VERSION" = "" ]
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

FILENAME="$HOME/Downloads/ScreensConnect-$LATEST_VERSION.zip"

echo "$NAME: Downloading $URL to $FILENAME"

 curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

## Move old version, if any

if [[ -e "$INSTALL_TO" ]]
then

	mv -vf "$INSTALL_TO" "$HOME/.Trash/Screens Connect.$INSTALLED_VERSION.app"

fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO"

ditto --noqtn -xk "$FILENAME" "$INSTALL_TO:h"

EXIT="$?"

if [[ "$EXIT" == "0" ]]
then
	echo "$NAME: Installation of $INSTALL_TO was successful."
	exit 0
else
	echo "$NAME: Installation of $INSTALL_TO failed (\$EXIT = $EXIT)\nThe downloaded file can be found at $FILENAME."
	exit 1
fi

exit 0
#
#EOF

