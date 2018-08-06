#!/bin/zsh -f
# Purpose: Download and install the latest version of SSH Tunnel Manager
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-15

NAME="$0:t:r"

INSTALL_TO='/Applications/SSH Tunnel Manager.app'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

	# Alternate URL in case the old one ever stops working
	#   https://updates.devmate.com/org.tynsoe.sshtunnelmanager.xml
XML_FEED='https://ssl.tynsoe.org/stm/stm.xml'

INFO=($(curl -sfL "$XML_FEED" \
	| tr -s ' ' '\012' \
	| egrep 'sparkle:shortVersionString|sparkle:version=|url=' \
	| head -3 \
	| sort \
	| awk -F'"' '/^/{print $2}'))

	# "Sparkle" will always come before "url" because of "sort"
MAJOR_VERSION="$INFO[1]"
LATEST_VERSION="$INFO[2]"
URL="$INFO[3]"

	# If any of these are blank, we should not continue
if [ "$INFO" = "" -o "$LATEST_VERSION" = "" -o "$URL" = "" -o "$MAJOR_VERSION" = "" ]
then
	echo "$NAME: Error: bad data received:
	INFO: $INFO
	MAJOR_VERSION: $MAJOR_VERSION
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	"
	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleVersion 2>/dev/null || echo '0'`

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

FILENAME="$HOME/Downloads/SSHTunnelManager-${MAJOR_VERSION}-${LATEST_VERSION}.zip"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

if [[ -e "$INSTALL_TO" ]]
then
	pgrep -xq "SSH Tunnel Manager" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "SSH Tunnel Manager" to quit'

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/SSH Tunnel Manager.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

ditto --noqtn -xk "$FILENAME" "$INSTALL_TO:h/"

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: Installation of $INSTALL_TO was successful."

else
	echo "$NAME: Installation of $INSTALL_TO failed (\$EXIT = $EXIT)\nThe downloaded file can be found at $FILENAME."
fi

[[ "$LAUNCH" = "yes" ]] open -a "$INSTALL_TO"

exit 0
#EOF
