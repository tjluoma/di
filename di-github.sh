#!/bin/zsh -f
# Purpose: download and install GitHub’s Mac app
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2014-09-30

NAME="$0:t:r"

INSTALL_TO='/Applications/GitHub Desktop.app'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleVersion 2>/dev/null || echo '0'`

OS_VER=`sw_vers -productVersion || echo '10.11'`

	# If you are up to date, you get an empty document with a 204 response code

RESPONSE=`curl --head -sfL "https://central.github.com/api/mac/latest?version=${INSTALLED_VERSION}&os_version=${OS_VER}" \
			| awk -F' ' '/^HTTP/{print $2}'`

if [[ "$RESPONSE" == "204" ]]
then
	echo "$NAME: Up to Date (Version $INSTALLED_VERSION)"
	exit 0
fi

INFO=($(curl -sfL "https://central.github.com/api/mac/latest?version=${INSTALLED_VERSION}&os_version=${OS_VER}" \
		| tr ',' '\012' \
		| egrep '"version"|"url"' \
		| head -2 \
		| awk -F'"' '//{print $4}'))

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

if [[ "$LATEST_VERSION" == "$INSTALLED_VERSION" ]]
then
	echo "$NAME: Up-To-Date ($INSTALLED_VERSION)"
	exit 0
fi

autoload is-at-least

is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

if [ "$?" = "0" ]
then
	echo "$NAME: Up-To-Date (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)."
	exit 0
fi

echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"

FILENAME="$HOME/Downloads/GitHub-$LATEST_VERSION.zip"

echo "$NAME: Downloading $URL to $FILENAME"

 curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

if [ -e "$INSTALL_TO" ]
then
		# If there's an installed
		# Quit app, if running
	pgrep -xq "GitHub Desktop" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "GitHub Desktop" to quit'

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/GitHub Desktop.$INSTALLED_VERSION.app"
fi

	# Install zip to /Applications/
echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

ditto --noqtn -xk "$FILENAME" "$INSTALL_TO:h/"


EXIT="$?"

if [ "$EXIT" = "0" ]
then

	echo "$NAME: Update/installation of $INSTALL_TO was successful"

else
	echo "$NAME: ditto failed (\$EXIT = $EXIT)"

	exit 1
fi


exit 0
#
#EOF
