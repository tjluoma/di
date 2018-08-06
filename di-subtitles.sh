#!/bin/zsh -f
# Purpose: Download and install latest version of Subtitlesapp.com
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2015-05-01

NAME="$0:t:r"

INSTALL_TO='/Applications/Subtitles.app'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

XML_FEED='https://subtitlesapp.com/updates.xml'

	# this XML file is... unusual. It's a huge blob of XML, most of which is XML-ified HTML, so
	# we use 'tidy' to force it into something more easily readable

	# CFBundleShortVersionString and CFBundleVersion: 3.2.11 are identical, so no need to check both

INFO=($(curl -sfL "$XML_FEED" \
	| tidy --input-xml yes --output-xml yes --show-warnings no --force-output yes --quiet yes --wrap 0 \
	| sed 's#&lt;#<#g ; s#&gt;#>#g ' \
	| fgrep 'sparkle:version=' \
	| head -1 \
	| tr -s ' ' '\012' \
	| sort \
	| egrep 'sparkle:version=|url=' \
	| awk -F'"' '/^/{print $2}'))

	# "Sparkle" will always come before "url" because of "sort"
LATEST_VERSION="$INFO[1]"

URL="$INFO[2]"

if [ "$INFO" = "" -o "$LATEST_VERSION" = "" -o "$URL" = "" ]
then
	echo "$NAME: Trying backup method to find URL and LATEST_VERSION"

	URL=`curl -sfL --head 'http://subtitlesapp.com/download/' | awk -F' ' '/^Location:/{print $2}' | tail -1 | tr -d '\r'`

	LATEST_VERSION=`echo "$URL:t:r" | tr -dc '[0-9].'`

fi

if [ "$LATEST_VERSION" = "" -o "$URL" = "" ]
then

	echo "$NAME: Cannot continue. Bad data from $XML_FEED:
	INFO: $INFO
	URL: $URL
	LATEST_VERSION: LATEST_VERSION
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

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-$LATEST_VERSION.zip"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

if [[ -e "$INSTALL_TO" ]]
then
	mv -f "$INSTALL_TO" "$HOME/.Trash/Subtitles.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO"

ditto -v --noqtn -xk "$FILENAME" "$INSTALL_TO:h"

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
