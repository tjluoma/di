#!/bin/zsh -f
# download and install PDFPenPro
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-02-12

NAME="$0:t:r"

## 2015-10-26 - rewritten to use
## https://updates.smilesoftware.com/com.smileonmymac.PDFpenPro.xml

INFO=($(curl -sfL 'https://updates.smilesoftware.com/com.smileonmymac.PDFpenPro.xml' \
| tr -s ' ' '\012' \
| egrep '^(sparkle:shortVersionString|url=)' \
| head -2 \
| sort \
| awk -F'"' '/^/{print $2}'))

LATEST_VERSION="$INFO[1]"

URL="$INFO[2]"

	# http://bashscripts.org/forum/viewtopic.php?f=16&t=1248

INSTALL_TO='/Applications/PDFpenPro.app'

INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info"  CFBundleShortVersionString 2>/dev/null`

autoload is-at-least

is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

if [ "$?" = "0" ]
then
	echo "$NAME: Up-To-Date (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"
	exit 0
fi

echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"


## Download it
FILENAME="$HOME/Downloads/PDFpenPro-$LATEST_VERSION.zip"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

## Move old version, if any

if [ -e "$INSTALL_TO" ]
then

	mv -vf "$INSTALL_TO" "$HOME/.Trash/PDFpenPro.$INSTALLED_VERSION.app"

fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO"

ditto --noqtn -xk "$FILENAME" "$INSTALL_TO:h"

exit 0

#
#EOF
