#!/bin/zsh -f
# Purpose: Download and install the latest version of Bartender 3
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-04-16

# 2018-07-10 - updated for Bartender 3
NAME="$0:t:r"

INSTALL_TO='/Applications/Bartender 3.app'

# INSTALL_TO='/Applications/Bartender 2.app'
# XML_FEED='http://www.macbartender.com/B2/updates/updates.php'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi


LAUNCH='yes'

XML_FEED='https://www.macbartender.com/B2/updates/updatesB3.php'


	# This will work even if there is a space in the enclosure URL
	# Don't indent this or you'll break 'sed'
IFS=$'\n' INFO=($(curl -sfL "$XML_FEED" \
| egrep 'sparkle:shortVersionString=|url=' \
| tail -1 \
| sed 's#" #"\
#g' \
| egrep 'sparkle:shortVersionString=|url=' \
| sed 's#<enclosure url="##g; s#"$##g; s#sparkle:shortVersionString="##g'))

URL=$(echo "$INFO[1]" | sed 's#.*http#http#g')

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

FILENAME="$HOME/Downloads/Bartender-$LATEST_VERSION.zip"

echo "$NAME: Downloading $URL to $FILENAME"

 curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

if [ -e "$INSTALL_TO" ]
then
	pgrep -xq "Bartender 3" && LAUNCH='yes' && osascript -e 'tell application "Bartender 3" to quit'

	mv -f "$INSTALL_TO" "$HOME/.Trash/Bartender 3.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

ditto --noqtn -xk "$FILENAME" "$INSTALL_TO:h/"


EXIT="$?"

if [ "$EXIT" = "0" ]
then

	echo "$NAME: Update/install of $INSTALL_TO successful"

else
	echo "$NAME: 'ditto' failed (\$EXIT = $EXIT)"

	exit 1
fi


if [ "$LAUNCH" = "yes" ]
then
	echo "$NAME: Launching Bartender 3"
	open -a "Bartender 3"
fi

exit 0
#
#EOF
