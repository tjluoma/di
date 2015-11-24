#!/bin/zsh -f
# Purpose:	download and install CodeRunner
# Date:		2014-12-13
# From:	  	Timothy J. Luoma
# Mail:		luomat at gmail dot com

NAME="$0:t:r"

INFO=($(curl -sfL "https://coderunnerapp.com/appcast.xml" \
			| tr -s ' ' '\012' \
			| egrep '^(url|sparkle:shortVersionString)=' \
			| head -2 \
			| awk -F'"' '//{print $2}'))

URL="$INFO[1]"

LATEST_VERSION="$INFO[2]"

if [ "$LATEST_VERSION" = "" -o "$URL" = "" ]
then
	echo "$NAME: Error: bad data received:\nLATEST_VERSION: $LATEST_VERSION\nURL: $URL"
	exit 0
fi

INSTALL_TO='/Applications/CodeRunner.app'

INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo '2.0.0'`

autoload is-at-least

is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

if [ "$?" = "0" ]
then
	echo "$NAME: Up-To-Date (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"
	exit 0
fi

echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"

FILENAME="$HOME/Downloads/CodeRunner-$LATEST_VERSION.zip"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

if [ -e "$INSTALL_TO" ]
then

	mv -vf "$INSTALL_TO" "$HOME/.Trash/CodeRunner.$INSTALLED_VERSION.app"

fi

ditto --noqtn -xk "$FILENAME" "$INSTALL_TO:h"


exit 0

#
#EOF
