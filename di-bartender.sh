#!/bin/zsh -f
# download and install Bartender
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-04-16

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

NAME="$0:t:r"

INSTALL_TO="/Applications/Bartender 2.app"

LAUNCH='no'

XML_FEED='http://www.macbartender.com/B2/updates/updates.php'

	# This will work even if there is a space in the enclosure URL
IFS=$'\n' INFO=($(curl -sfL "$XML_FEED" \
| egrep 'sparkle:shortVersionString=|url=' \
| tail -1 \
| sed 's#" #"\
#g' \
| egrep 'sparkle:shortVersionString=|url=' \
| sed 's#<enclosure url="##g; s#"$##g; s#sparkle:shortVersionString="##g'))

URL="$INFO[1]"

LATEST_VERSION="$INFO[2]"

if [ "$INFO" = "" -o "$LATEST_VERSION" = "" -o "$URL" = "" ]
then
	echo "$NAME: Error: bad data received:\nINFO: $INFO"
	exit 0
fi

INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo '2.0.0'`

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

FILENAME="$HOME/Downloads/Bartender-$LATEST_VERSION.zip"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

if [ -e "$INSTALL_TO" ]
then
	pgrep -xq "Bartender 2" && LAUNCH='yes' && osascript -e 'tell application "Bartender 2" to quit'

	mv -f "$INSTALL_TO" "$HOME/.Trash/Bartender 2.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

ditto --noqtn -xk "$FILENAME" "$INSTALL_TO:h/"

if [ "$LAUNCH" = "yes" ]
then
	echo "$NAME: Launching Bartender 2"
	open -a "Bartender 2"
fi

exit 0
#
#EOF

