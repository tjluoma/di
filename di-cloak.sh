#!/bin/zsh -f
# Purpose:
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-06

NAME="$0:t:r"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

INSTALL_TO='/Applications/Cloak.app'

INFO=($(curl -sfL 'https://www.getcloak.com/updates/osx/public/' \
| tr ' ' '\012' \
| egrep '^(url|sparkle:version)=' \
| tail -2 \
| awk -F'"' '//{print $2}'))

URL="$INFO[1]"
LATEST_VERSION="$INFO[2]"

INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo '2.0.0'`

autoload is-at-least

is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

if [ "$?" = "0" ]
then
	echo "$NAME: Up-To-Date (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"
	exit 0
fi

echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"

FILENAME="$HOME/Downloads/Cloak-$LATEST_VERSION.dmg"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
		| fgrep -A 1 '<key>mount-point</key>' \
		| tail -1 \
		| sed 's#</string>.*##g ; s#.*<string>##g')

if [[ "$MNTPNT" == "" ]]
then
		echo "$NAME: Failed to mount $FILENAME. (MNTPNT is empty)"
		exit 0
fi

echo "$MNTPNT"

if [ -e "$INSTALL_TO" ]
then
		# Quit app, if running
	pgrep -xq "Cloak" \
	&& LAUNCH='yes' \
	&& killall Cloak

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/Cloak.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

ditto --noqtn "$MNTPNT/Cloak.app" "$INSTALL_TO"

diskutil eject "$MNTPNT"

[[ "$LAUNCH" == "yes" ]] && open -a "$INSTALL_TO"

exit 0
#EOF
