#!/bin/zsh -f
# Purpose: Download and install latest version of PDFPenPro
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-02-12

NAME="$0:t:r"
INSTALL_TO='/Applications/PDFpenPro.app'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

## 2015-10-26 - rewritten to use
## https://updates.smilesoftware.com/com.smileonmymac.PDFpenPro.xml

# 2018-07-17 - found alternate URL which seems to have identical info:
# https://updates.devmate.com/com.smileonmymac.PDFpenPro.xml

INFO=($(curl -sfL 'https://updates.smilesoftware.com/com.smileonmymac.PDFpenPro.xml' \
		| tr -s ' ' '\012' \
		| egrep '^(sparkle:shortVersionString|url=)' \
		| head -2 \
		| sort \
		| awk -F'"' '/^/{print $2}'))

LATEST_VERSION="$INFO[1]"

URL="$INFO[2]"

	# If any of these are blank, we should not continue
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


## Download it
FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-$LATEST_VERSION.zip"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download failed (EXIT = $EXIT)" && exit 0


## Move old version, if any

if [[ -e "$INSTALL_TO" ]]
then

	mv -vf "$INSTALL_TO" "$HOME/.Trash/PDFpenPro.$INSTALLED_VERSION.app"

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
