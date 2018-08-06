#!/bin/zsh -f
# Purpose: Download and install latest version of TextBar
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2015-04-18

NAME="$0:t:r"

INSTALL_TO='/Applications/TextBar.app'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

## 2018-07-17 - this was the old XML_FEED that I was using
# XML_FEED='http://www.richsomerfield.com/apps/textbar/sparkle_textbar.xml'

XML_FEED='https://raw.githubusercontent.com/richie5um/richie5um.github.io/master/apps/textbar/sparkle_textbar.xml'

# sparkle:version is the ONLY field available in XML_FEED as far as version numbers go

INFO=($(curl -sfL "$XML_FEED" \
		| tr ' ' '\012' \
		| egrep '^(url|sparkle:version)=' \
		| head -2 \
		| sort \
		| awk -F'"' '//{print $2}'))

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

		# Get the currently install version number
	INSTALLED_VERSION=`defaults read ${INSTALL_TO}/Contents/Info CFBundleShortVersionString`

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

	# Download the latest zip
echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

# if running, quit
pgrep -xq TextBar \
&& osascript -e 'tell application "TextBar" to quit' \
&& LAUNCH='yes'

if [[ -e "$INSTALL_TO" ]]
then
	mv -f "$INSTALL_TO" "$HOME/.Trash/TextBar.$INSTALLED_VERSION.app"
fi

	# unzip the file we downloaded into /Applications/ aka the 'head' folder
	# of $INSTALL_TO

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h"
ditto --noqtn -xk "$FILENAME" "$INSTALL_TO:h/"

if [[ "$EXIT" == "0" ]]
then
	echo "$NAME: Installation of $INSTALL_TO was successful."

	[[ "$LAUNCH" = "yes" ]] && open -a TextBar

	exit 0
else
	echo "$NAME: Installation of $INSTALL_TO failed (\$EXIT = $EXIT)\nThe downloaded file can be found at $FILENAME."
	exit 1
fi

exit 0
#
#EOF
