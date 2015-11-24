#!/bin/zsh -f
# Purpose: 
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-14

NAME="$0:t:r"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

XML_FEED='http://update.omnigroup.com/appcast/com.omnigroup.OmniDiskSweeper/'

IFS=$'\n' 

INFO=($(curl -sfL "$XML_FEED" \
| tidy --input-xml yes --output-xml yes --show-warnings no --force-output yes --quiet yes --wrap 0 \
| egrep 'omniappcast:marketingVersion|enclosure' \
| head -2))

LATEST_VERSION=`echo "$INFO[1]" | awk -F'>|<' '//{print $3}' `

URL=`echo "$INFO[2]" | awk -F'"' '/url=/{print $6}'`

INSTALL_TO='/Applications/OmniDiskSweeper.app'

INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo '0'`

autoload is-at-least

is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

if [ "$?" = "0" ]
then
	echo "$NAME: Up-To-Date (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"
	exit 0
fi

echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"

FILENAME="$HOME/Downloads/OmniDiskSweeper-$LATEST_VERSION.dmg"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
		| fgrep -A 1 '<key>mount-point</key>' \
		| tail -1 \
		| sed 's#</string>.*##g ; s#.*<string>##g')

if [ -e "$INSTALL_TO" ]
then
		# Quit app, if running
	pgrep -xq "OmniDIskSweeper" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "OmniDIskSweeper" to quit'

		# move installed version to trash 
	mv -vf "$INSTALL_TO" "$HOME/.Trash/OmniDIskSweeper.$INSTALLED_VERSION.app"
fi

ditto -v "$MNTPNT/$INSTALL_TO:t" "$INSTALL_TO"

if (( $+commands[unmount.sh] ))
then
	unmount.sh "$MNTPNT"
else
	diskutil eject "$MNTPNT"
fi



exit 0
#EOF
