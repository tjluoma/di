#!/bin/zsh -f
# Purpose: Download and install the latest version of Accordance
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-02

NAME="$0:t:r"

INSTALL_TO='/Applications/Accordance.app'

if [ -e "/Users/luomat/.path" ]
then
	source "/Users/luomat/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

# INFO=($(curl -sfL 'http://accordancefiles1.com/php/v11/profileInfo.php' \
# | tr ' ' '\012' \
# | egrep '^(url|sparkle:shortVersionString)=' \
# | head -2 \
# | awk -F'"' '//{print $2}'))

INFO=($(curl -sfL 'https://accordancefiles1.com/php/v12/profileInfo.php' \
| tr ' ' '\012' \
| egrep '^(url|sparkle:shortVersionString)=' \
| head -2 \
| awk -F'"' '//{print $2}'))

URL="$INFO[1]"

LATEST_VERSION="$INFO[2]"

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

	INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo '0'`

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

FILENAME="$HOME/Downloads/Accordance-$LATEST_VERSION.zip"

echo "$NAME: Downloading $URL to $FILENAME"

 curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

if [ -e "$INSTALL_TO" ]
then
		# Quit app, if running
	pgrep -xq "Accordance" && LAUNCH='yes' && osascript -e 'tell application "Accordance" to quit'

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/Accordance.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

ditto --noqtn -xk "$FILENAME" "$INSTALL_TO:h/"


EXIT="$?"

if [ "$EXIT" = "0" ]
then

	echo "$NAME: Installation of $INSTALL_TO successful"

else
	echo "$NAME: 'ditto' failed (\$EXIT = $EXIT)"

	exit 1
fi


[[ "$LAUNCH" = "yes" ]] && open --background "$INSTALL_TO"


exit 0
#EOF
