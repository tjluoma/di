#!/bin/zsh -f
# Purpose: Download and install the latest version of Trip Mode
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2016-05-10

NAME="$0:t:r"

INSTALL_TO='/Applications/TripMode.app'

HOMEPAGE="https://www.tripmode.ch"

DOWNLOAD_PAGE="https://www.tripmode.ch/thank-you-for-downloading-tripmode/"

SUMMARY="Easily block unwanted apps from accessing the Internet the second you connect to a hotspot. Save data. Save money."

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

# Found via cask
XML_FEED='https://www.tripmode.ch/app/appcast.xml'

INFO=($(curl -sfL "$XML_FEED" \
	| tr ' ' '\012' \
	| egrep '^(url|sparkle:shortVersionString|sparkle:version)=' \
	| head -3 \
	| sort \
	| awk -F'"' '//{print $2}'))

LATEST_VERSION="$INFO[1]"

LATEST_BUILD="$INFO[2]"

URL="$INFO[3]"

if [ "$INFO" = "" -o "$LATEST_VERSION" = "" -o "$LATEST_BUILD" = "" -o "$URL" = "" ]
then
	echo "$NAME: Bad data from $XML_FEED
	INFO: $INFO
	LATEST_VERSION: $LATEST_VERSION
	LATEST_BUILD: $LATEST_BUILD
	URL: $URL
	"

	exit 1
fi


if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleShortVersionString)

	INSTALLED_BUILD=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleVersion)

	if [ "$LATEST_VERSION" = "$INSTALLED_VERSION" -a "$LATEST_BUILD" = "$INSTALLED_BUILD" ]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION/$INSTALLED_BUILD)"
		exit 0
	fi

	autoload is-at-least

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	VERSION_COMPARE="$?"

	is-at-least "$LATEST_BUILD" "$INSTALLED_BUILD"

	BUILD_COMPARE="$?"

	if [ "$VERSION_COMPARE" = "0" -a "$BUILD_COMPARE" = "0" ]
	then
		echo "$NAME: Installed version ($INSTALLED_VERSION/$INSTALLED_BUILD) is ahead of official version $LATEST_VERSION/$LATEST_BUILD"
		exit 0
	fi

	echo "$NAME: Outdated: $INSTALLED_VERSION/$INSTALLED_BUILD vs $LATEST_VERSION/$LATEST_BUILD"
fi

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}_${LATEST_BUILD}.dmg"

if (( $+commands[lynx] ))
then

	RELEASE_NOTES_URL=$(curl -sfL "$XML_FEED" \
		| sed '1,/<sparkle:releaseNotesLink>/d; /<\/sparkle:releaseNotesLink>/,$d')

	( echo "$NAME: Release Notes for $INSTALL_TO:t:r:" ;
		lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines "${RELEASE_NOTES_URL}" ;
		echo "\nSource: <$RELEASE_NOTES_URL>" ) | tee "$FILENAME:r.txt"

fi

	# Download the latest version
echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
			| fgrep -A 1 '<key>mount-point</key>' \
			| tail -1 \
			| sed 's#</string>.*##g ; s#.*<string>##g')

if [[ "$MNTPNT" == "" ]]
then
	echo "$NAME: MNTPNT is empty"
	exit 0
else
	echo "$NAME: Mounted $FILENAME at $MNTPNT"
fi

if [[ -e "$INSTALL_TO" ]]
then
	mv -vf "$INSTALL_TO" "$HOME/.Trash/TripMode.${INSTALLED_VERSION}-${INSTALLED_BUILD}.app"
fi

echo "$NAME:  Installing $MNTPNT/TripMode.app to $INSTALL_TO"

ditto --noqtn "$MNTPNT/TripMode.app" "$INSTALL_TO"

EXIT="$?"

if [[ "$EXIT" == "0" ]]
then
	echo "$NAME: Installation of $INSTALL_TO was successful."
else
	echo "$NAME: Installation of $INSTALL_TO failed (\$EXIT = $EXIT)\nThe downloaded file can be found at $FILENAME."
fi

diskutil eject "$MNTPNT"

exit 0

