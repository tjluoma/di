#!/bin/zsh -f
# Purpose: download and install CodeRunner
#
# Date:		2014-12-13
# From:	  	Timothy J. Luoma
# Mail:		luomat at gmail dot com

NAME="$0:t:r"

INSTALL_TO='/Applications/CodeRunner.app'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

XML_FEED="https://coderunnerapp.com/appcast.xml"

INFO=($(curl -sfL "$XML_FEED" \
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

if [ "$INFO" = "" -o "$LATEST_VERSION" = "" -o "$URL" = "" ]
then
	echo "$NAME: Error: bad data received:
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

FILENAME="$HOME/Downloads/CodeRunner-$LATEST_VERSION.zip"

echo "$NAME: Downloading $URL to $FILENAME"

 curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0


if [[ -e "$INSTALL_TO" ]]
then

	mv -vf "$INSTALL_TO" "$HOME/.Trash/CodeRunner.$INSTALLED_VERSION.app"

fi

ditto --noqtn -xk "$FILENAME" "$INSTALL_TO:h"

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: Installation of $INSTALL_TO was successful."

else
	echo "$NAME: Installation of $INSTALL_TO failed (ditto \$EXIT = $EXIT)\nThe downloaded file can be found at $FILENAME."
	exit 1
fi

exit 0

#
#EOF
