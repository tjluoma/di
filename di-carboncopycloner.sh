#!/bin/zsh -f
# Purpose: 
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2016-05-02

NAME="$0:t:r"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

INSTALL_TO='/Applications/Carbon Copy Cloner.app'

	## NOTE: If nothing is installed, we need to pretend we have at least version 4
	## 			or else we will get version 3 
INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo '4.0.0'`

	## NOTE: If nothing is installed, we need to pretend we have at least version 4000
	## 			or else we will get version 3 	
INSTALLED_BUNDLE_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleVersion 2>/dev/null || echo '4000'`

OS_MINOR=`sw_vers -productVersion | cut -d. -f 2`

OS_BUGFIX=`sw_vers -productVersion | cut -d. -f 3`

XML_FEED="https://bombich.com/software/updates/ccc.php?os_minor=$OS_MINOR&os_bugfix=$OS_BUGFIX&ccc=$INSTALLED_BUNDLE_VERSION&beta=0&locale=en"

## If you want betas, use this line  
# XML_FEED="https://bombich.com/software/updates/ccc.php?os_minor=$OS_MINOR&os_bugfix=$OS_BUGFIX&ccc=$INSTALLED_BUNDLE_VERSION&beta=1&locale=en"

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


if [[ "$LATEST_VERSION" == "$INSTALLED_VERSION" ]]
then
	echo "$NAME: Up-To-Date ($INSTALLED_VERSION)"
	exit 0
fi

autoload is-at-least

is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

if [ "$?" = "0" ]
then
	echo "$NAME: Up-To-Date (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"
	exit 0
fi

echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"


FILENAME="$HOME/Downloads/CarbonCopyCloner-${LATEST_VERSION}.zip"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

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
