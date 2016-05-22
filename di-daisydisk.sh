#!/bin/zsh -f
# Purpose: Download and install latest version of DaisyDisk from http://daisydiskapp.com
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-24

NAME="$0:t:r"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

INSTALL_TO='/Applications/DaisyDisk.app'

OS_VER=`sw_vers -productVersion`

INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo '4'`

# XML_FEED="http://www.daisydiskapp.com/downloads/appcastFeed.php?osVersion=${OS_VER}&appVersion=${INSTALLED_VERSION}&appEdition=Standard"

## 2016-05-22 - we intentionally tell it we are using 4.0 so that the feed will show us the most recent version
##				because that is what we need to compare against what we have. Otherwise we get an empty feed back.
XML_FEED="http://www.daisydiskapp.com/downloads/appcastFeed.php?osVersion=${OS_VER}&appVersion=4.0&appEdition=Standard"

INFO=($(curl -sfL "$XML_FEED" \
| tr -s ' ' '\012' \
| egrep 'sparkle:version=|url=' \
| head -2 \
| sort \
| awk -F'"' '/^/{print $2}'))

	# "Sparkle" will always come before "url" because of "sort"
LATEST_VERSION="$INFO[1]"
URL="$INFO[2]"

	# If any of these are blank, we should not continue
if [ "$INFO" = "" -o "$LATEST_VERSION" = "" -o "$URL" = "" ]
then
	echo "$NAME: Error: bad data received:\nINFO: $INFO"
	exit 0
fi

autoload is-at-least

is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

if [ "$?" = "0" ]
then
	echo "$NAME: Up-To-Date ($LATEST_VERSION)"
	exit 0
fi

echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"

FILENAME="$HOME/Downloads/DaisyDisk-${LATEST_VERSION}.zip"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download failed (EXIT = $EXIT)" && exit 0

if [ -e "$INSTALL_TO" ]
then
		# Quit app, if running
	pgrep -xq "DaisyDisk" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "DaisyDisk" to quit'

		# move installed version to trash 
	mv -vf "$INSTALL_TO" "$HOME/.Trash/DaisyDisk.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

	# Extract from the .zip file and install (this will leave the .zip file in place)
ditto --noqtn -xk "$FILENAME" "$INSTALL_TO:h/"

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: Installation of $INSTALL_TO was successful."
	
	[[ "$LAUNCH" == "yes" ]] && open -a "$INSTALL_TO"
	
else
	echo "$NAME: Installation of $INSTALL_TO failed (\$EXIT = $EXIT)\nThe downloaded file can be found at $FILENAME."
fi



exit 0
#EOF
