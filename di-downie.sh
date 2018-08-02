#!/bin/zsh -f
# Purpose: Download and install the latest version of Downie
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2016-05-07

NAME="$0:t:r"

INSTALL_TO='/Applications/Downie.app'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

####|####|####|####|####|####|####|####|####|####|####|####|####|####|####

XML_FEED="http://trial.charliemonroe.net/downie/updates_2.3.xml"

INFO=($(curl -sfL "$XML_FEED" \
		| tr -s ' ' '\012' \
		| egrep 'sparkle:shortVersionString=|url=' \
		| head -2 \
		| sort \
		| awk -F'"' '/^/{print $2}'))

	# "Sparkle" will always come before "url" because of "sort"
LATEST_VERSION="$INFO[1]"
URL="$INFO[2]"

if [ "$INFO" = "" -o "$LATEST_VERSION" = "" -o "$URL" = "" ]
then
	echo "$NAME: Error: bad data received:
	INFO: $INFO
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	"

	exit 1
fi

####|####|####|####|####|####|####|####|####|####|####|####|####|####|####

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo '0'`

	if [[ "$LATEST_VERSION" == "$INSTALLED_VERSION" ]]
	then
		echo "$NAME: Up-To-Date (Installed/Latest Version = $INSTALLED_VERSION)"
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

fi

####|####|####|####|####|####|####|####|####|####|####|####|####|####|####

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}.zip"

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

####|####|####|####|####|####|####|####|####|####|####|####|####|####|####

if [ -e "$INSTALL_TO" ]
then
		# Quit app, if running
	pgrep -xq "Downie" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "Downie" to quit'

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/Downie.$INSTALLED_VERSION.app"
fi

####|####|####|####|####|####|####|####|####|####|####|####|####|####|####

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

	# Extract from the .zip file and install (this will leave the .zip file in place)
ditto --noqtn -xk "$FILENAME" "$INSTALL_TO:h/"

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: Installation of $INSTALL_TO was successful."

	[[ "$LAUNCH" == "yes" ]] && open -a "$INSTALL_TO"

else
	echo "$NAME: Installation of $INSTALL_TO failed (ditto \$EXIT = $EXIT)\nThe downloaded file can be found at $FILENAME."

	exit 1
fi

####|####|####|####|####|####|####|####|####|####|####|####|####|####|####


exit 0
#EOF
