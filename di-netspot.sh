#!/usr/bin/env zsh -f
# Purpose: Download and install the latest version of NetSpot
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-12-23

NAME="$0:t:r"

XML_FEED='https://www.netspotapp.com/updates/netspot2-appcast.xml'

INSTALL_TO='/Applications/NetSpot.app'

HOMEPAGE="https://www.netspotapp.com"

DOWNLOAD_PAGE="https://www.netspotapp.com/download-mac.html"

SUMMARY="NetSpot is the only professional app for wireless site surveys, Wi-Fi analysis, and troubleshooting on Mac OS X and Windows."

RELEASE_NOTES_URL=$(curl -sfL "$XML_FEED" \
	| sed '1,/<sparkle:releaseNotesLink>/d; /<\/sparkle:releaseNotesLink>/,$d' \
	| sed 's# *##g' \
	| tr -d '[:cntrl:]')

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

	# CFBundleVersion and CFBundleShortVersionString are identical

INFO=($(curl -sfL "$XML_FEED" \
		| tr -s ' ' '\012' \
		| egrep 'sparkle:version=|url=' \
		| head -2 \
		| sort \
		| awk -F'"' '/^/{print $2}'))

	# "Sparkle" will always come before "url" because of "sort"
LATEST_VERSION="$INFO[1]"
URL="$INFO[2]"

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

	INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString `

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

	if [[ -e "$INSTALL_TO/Contents/_MASReceipt/receipt" ]]
	then
		echo "$NAME: $INSTALL_TO was installed from the Mac App Store and cannot be updated by this script."
		echo "	See <https://apps.apple.com/us/app/netspot-wifi-survey-wireless-scanner/id514951692?mt=12> or"
		echo "	<macappstore://apps.apple.com/us/app/netspot-wifi-survey-wireless-scanner/id514951692>"
		echo "	Please use the App Store app to update it: <macappstore://showUpdatesPage?scan=true>"
		exit 0
	fi

fi

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}.dmg"

if (( $+commands[lynx] ))
then

	( echo "$NAME: Release Notes for $INSTALL_TO:t:r ($LATEST_VERSION):" ;
		curl -sfL "$RELEASE_NOTES_URL" \
		| sed '1,/<div class="content">/d; /<\/div>/,$d' \
		| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin ;
		echo "\nSource: <$RELEASE_NOTES_URL>" ) | tee "$FILENAME:r.txt"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

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
	pgrep -xq "$INSTALL_TO:t:r" \
	&& LAUNCH='yes' \
	&& osascript -e "tell application \"$INSTALL_TO:t:r\" to quit"

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/NetSpot.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $MNTPNT/$INSTALL_TO:t to $INSTALL_TO"

ditto --noqtn -v "$MNTPNT/$INSTALL_TO:t" "$INSTALL_TO"

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: Installation of $INSTALL_TO successful"

else
	echo "$NAME: ditto failed (\$EXIT = $EXIT)"

	exit 1
fi

diskutil eject "$MNTPNT"

[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"

exit 0
#EOF
