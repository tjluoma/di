#!/bin/zsh -f
# Purpose: Download and install the latest version of OmniDiskSweeper
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-14

NAME="$0:t:r"

INSTALL_TO='/Applications/OmniDiskSweeper.app'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

# @TODO - change this to download the 'tbz2' version instead of the DMG?

XML_FEED='http://update.omnigroup.com/appcast/com.omnigroup.OmniDiskSweeper/'

IFS=$'\n'

INFO=($(curl -sfL "$XML_FEED" \
| tidy --input-xml yes --output-xml yes --show-warnings no --force-output yes --quiet yes --wrap 0 \
| egrep 'omniappcast:marketingVersion|enclosure' \
| head -2))

LATEST_VERSION=`echo "$INFO[1]" | awk -F'>|<' '//{print $3}' `

URL=`echo "$INFO[2]" | awk -F'"' '/url=/{print $6}'`

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

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-$LATEST_VERSION.dmg"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download failed (EXIT = $EXIT)" && exit 0




MNTPNT=$(echo -n "Y" | hdid -plist "$FILENAME" 2>/dev/null | fgrep '/Volumes/' | sed 's#</string>##g ; s#.*<string>##g')

if [ -e "$INSTALL_TO" ]
then
		## Quit app, if running
		# 	pgrep -xq "OmniDIskSweeper" \
		# 	&& LAUNCH='yes' \
		# 	&& osascript -e 'tell application "OmniDIskSweeper" to quit'

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/OmniDIskSweeper.$INSTALLED_VERSION.app"
fi

ditto --noqtn -v "$MNTPNT/$INSTALL_TO:t" "$INSTALL_TO"

if (( $+commands[unmount.sh] ))
then
	unmount.sh "$MNTPNT"
else
	diskutil eject "$MNTPNT"
fi



exit 0
#EOF
