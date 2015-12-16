#!/bin/zsh -f
# Purpose: Download and install (or update) the latest version of Logos.com for Mac
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-19

NAME="$0:t:r"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

XML_FEED='https://clientservices.logos.com/update/v1/feed/logos6-mac/stable.xml'

#<link href="https://downloads.logoscdn.com/LBS6/Installer/6.7.0.0044/LogosMac.dmg" logos:version="6.7.0.0044" />
#<logos:version>6.7.0.0044</logos:version>

INFO=($(curl -sfL "$XML_FEED" \
| tidy --char-encoding utf8 --force-output yes --input-xml yes --markup yes --output-xhtml no --output-xml yes --quiet yes --show-errors 0 --show-warnings no --wrap 0 \
| egrep 'link href|logos:version' \
| head -2 \
| sed 's#<logos:version>##g ; s#</logos:version>##g ; s#<link href="##g; s#" .*##g'))

URL="$INFO[1]"

#LATEST_VERSION=`echo "$INFO[2]" | sed 's#\.000#.#g ; s#\.00#.#g' `

LATEST_VERSION="$INFO[2]"

INSTALL_TO="/Applications/Logos.app"

INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo '6.0.0.0'`

autoload is-at-least

is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

if [ "$?" = "0" ]
then
	echo "$NAME: Up-To-Date (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"
	exit 0
fi

echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"

FILENAME="$HOME/Downloads/Logos-$LATEST_VERSION.dmg"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download failed (EXIT = $EXIT)" && exit 0


MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
	| fgrep -A 1 '<key>mount-point</key>' \
	| tail -1 \
	| sed 's#</string>.*##g ; s#.*<string>##g')

if [[ "$MNTPNT" == "" ]]
then
	echo "$NAME: MNTPNT is empty"
	exit 1
fi


if [ -e "$INSTALL_TO" ]
then
		# Quit app, if running
	pgrep -xq "Logos" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "Logos" to quit'

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/Logos.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $MNTPNT/Logos.app to $INSTALL_TO"

ditto -v "$MNTPNT/Logos.app" "$INSTALL_TO"

diskutil eject "$MNTPNT"

open "$INSTALL_TO"

exit 0
#EOF
