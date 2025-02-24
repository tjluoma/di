#!/usr/bin/env zsh -f
# Purpose: 	Download and install the latest version of Sequel Pro
#
# From:		Timothy J. Luoma
# Mail:		luomat at gmail dot com
# Date:		2015-11-14
# Verified:	2025-02-23

NAME="$0:t:r"

INSTALL_TO="/Applications/Sequel Pro.app"

HOMEPAGE="https://www.sequelpro.com"

# DOWNLOAD_PAGE="https://sequelpro.com/download"

DOWNLOAD_PAGE="https://sequelpro.com/release?do=download-latest"

SUMMARY="Sequel Pro is a fast, easy-to-use Mac database management application for working with MySQL databases."

XML_FEED="https://www.sequelpro.com/appcast/app-releases.xml"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

INFO=($(curl -sfL "$XML_FEED" \
	| tr -s ' ' '\012' \
	| egrep 'sparkle:version=|sparkle:shortVersionString=|url=' \
	| head -3 \
	| sort \
	| awk -F'"' '/^/{print $2}'))

LATEST_VERSION="$INFO[1]"
LATEST_BUILD="$INFO[2]"
URL="$INFO[3]"

	# If any of these are blank, we should not continue
if [ "$INFO" = "" -o "$LATEST_BUILD" = "" -o "$URL" = "" -o "$LATEST_VERSION" = "" ]
then
	echo "$NAME: Error: bad data received:
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

	autoload is-at-least

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	VERSION_COMPARE="$?"

	is-at-least "$LATEST_BUILD" "$INSTALLED_BUILD"

	BUILD_COMPARE="$?"

	if [ "$VERSION_COMPARE" = "0" -a "$BUILD_COMPARE" = "0" ]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION/$INSTALLED_BUILD)"
		exit 0
	fi

	echo "$NAME: Outdated: $INSTALLED_VERSION/$INSTALLED_BUILD vs $LATEST_VERSION/$LATEST_BUILD"

	FIRST_INSTALL='no'

else

	FIRST_INSTALL='yes'
fi

FILENAME="$HOME/Downloads/SequelPro-${LATEST_VERSION}_${LATEST_BUILD}.dmg"

if (( $+commands[lynx] ))
then

	RELEASE_NOTES_URL="https://www.sequelpro.com/appcast/app-releases.xml"

	( echo "$NAME: Release Notes for $INSTALL_TO:t:r ($LATEST_VERSION/$LATEST_BUILD):" ;
		curl -sfL "$RELEASE_NOTES_URL" \
		| sed '1,/CDATA/d; /<\/description>/,$d' \
		| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin ;
		echo "\nSource: XML_FEED <$RELEASE_NOTES_URL>" ) | tee "$FILENAME:r.txt"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

echo "$NAME: Mounting $FILENAME:"

MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
	| fgrep -A 1 '<key>mount-point</key>' \
	| tail -1 \
	| sed 's#</string>.*##g ; s#.*<string>##g')

if [[ "$MNTPNT" == "" ]]
then
	echo "$NAME: MNTPNT is empty"
	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then
	pgrep -qx "$INSTALL_TO:t:r" && LAUNCH='yes' && killall "$INSTALL_TO:t:r"
	mv -f "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.$INSTALLED_BUILD.$RANDOM.app"
fi

echo "$NAME: Installing '$MNTPNT/$INSTALL_TO:t' to '$INSTALL_TO': "

ditto --noqtn -v "$MNTPNT/$INSTALL_TO:t" "$INSTALL_TO"

EXIT="$?"

if [[ "$EXIT" == "0" ]]
then
	echo "$NAME: Successfully installed $INSTALL_TO"
else
	echo "$NAME: ditto failed"

	exit 1
fi

echo "$NAME: Unmounting $MNTPNT:"

diskutil eject "$MNTPNT"

exit 0
#EOF
