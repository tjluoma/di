#!/bin/zsh -f
# Purpose: Download and install the latest version of Sharpshooter
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-07-10

NAME="$0:t:r"

INSTALL_TO='/Applications/Sharpshooter.app'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

LAUNCH='no'

XML_FEED='http://www.kerlmax.com/products/sharpshooter/sharpshooter_v2_appcast.php'

# sparkle:shortVersionString and sparkle:version are identical, so no need to check both

	# This will work even if there is a space in the enclosure URL
IFS=$'\n' INFO=($(curl -sfL "$XML_FEED" \
	| egrep 'sparkle:shortVersionString=|url=' \
	| head -2 \
	| sed 's#.*url="##g; s#"$##g; s#.*sparkle:shortVersionString="##g'))

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

FILENAME="$HOME/Downloads/Sharpshooter-$LATEST_VERSION.zip"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

if [ -e "$INSTALL_TO" ]
then
		# Check to see if the app itself is running
	pgrep -xq "Sharpshooter" && LAUNCH='yes' && osascript -e 'tell application "Sharpshooter" to quit'

		# Check to see if the app's agent (menu bar helper) is running
	pgrep -xq "SharpshooterAgent" && LAUNCH='yes' && osascript -e 'tell application "SharpshooterAgent" to quit'

	mv -f "$INSTALL_TO" "$HOME/.Trash/Sharpshooter.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

ditto --noqtn -xk "$FILENAME" "$INSTALL_TO:h/"

if [[ "$EXIT" == "0" ]]
then
	echo "$NAME: Installation of $INSTALL_TO was successful."
	exit 0
else
	echo "$NAME: Installation of $INSTALL_TO failed (\$EXIT = $EXIT)\nThe downloaded file can be found at $FILENAME."
	exit 1
fi

if [ "$LAUNCH" = "yes" ]
then
	echo "$NAME: Launching Sharpshooter"
	open -a "Sharpshooter"
	open -a "SharpshooterAgent" || open -b com.kerlmax.SharpshooterAgent
fi

exit 0
#
#EOF
