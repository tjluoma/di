#!/bin/zsh -f
# Purpose: Download and install the latest version of Vellum
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2015-09-24

NAME="$0:t:r"

DIR="$HOME/Downloads"

INSTALL_TO='/Applications/Vellum.app'

XML_FEED="https://get.180g.co/updates/vellum/"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi


INFO=($(curl -sfL "$XML_FEED" \
	| tr ' ' '\012' \
	| egrep '^(url|sparkle:shortVersionString|sparkle:version)=' \
	| head -3 \
	| sort \
	| awk -F'"' '//{print $2}'))

LATEST_VERSION="$INFO[1]"

LATEST_BUILD="$INFO[2]"

URL="$INFO[3]"

if [ "$INFO" = "" -o "$LATEST_VERSION" = "" -o "$LATEST_BUILD" = "" -o "$URL" = "" ]
then
	echo "$NAME: Bad data from $XML_FEED
	INFO: $INFO
	LATEST_VERSION: $LATEST_VERSION
	LATEST_BUILD: $LATEST_BUILD
	URL: $URL
	"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleShortVersionString)

	INSTALLED_BUILD=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleVersion)

	if [ "$LATEST_VERSION" = "$INSTALLED_VERSION" -a "$LATEST_BUILD" = "$INSTALLED_BUILD" ]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION/$INSTALLED_BUILD)"
		exit 0
	fi

	autoload is-at-least

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	VERSION_COMPARE="$?"

	is-at-least "$LATEST_BUILD" "$INSTALLED_BUILD"

	BUILD_COMPARE="$?"

	if [ "$VERSION_COMPARE" = "0" -a "$BUILD_COMPARE" = "0" ]
	then
		echo "$NAME: Installed version ($INSTALLED_VERSION/$INSTALLED_BUILD) is ahead of official version $LATEST_VERSION/$LATEST_BUILD"
		exit 0
	fi

	echo "$NAME: Outdated: $INSTALLED_VERSION/$INSTALLED_BUILD vs $LATEST_VERSION/$LATEST_BUILD"
fi

####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
#		This is where we do the actual download
#

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}-${LATEST_BUILD}.zip"

	# Download the latest zip
echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && exit 0

if [[ -e "$INSTALL_TO" ]]
then
	mv -vf "$INSTALL_TO" "$HOME/.Trash/Vellum.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h"

ditto --noqtn -xk "$FILENAME" "$INSTALL_TO:h/"

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
