#!/usr/bin/env zsh -f
# Purpose: 	Download and install the latest version of MacUpdater
#
# From:		Timothy J. Luoma
# Mail:		luomat at gmail dot com
# Date:		2018-07-27; 2019-11-07 switched to DMG instead of zip
# Verified:	2025-02-24

NAME="$0:t:r"

INSTALL_TO='/Applications/MacUpdater.app'

HOMEPAGE="https://www.corecode.io/macupdater/"

DOWNLOAD_PAGE="https://www.corecode.io/downloads/macupdater_latest.dmg"

SUMMARY="MacUpdater can automatically track the latest updates of all applications installed on your Mac. "

# XML_FEED='https://www.corecode.io/macupdater/macupdater.xml'  ## VERSION 1

XML_FEED='https://www.corecode.io/macupdater/macupdater3.xml'

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

	# RELEASE_NOTES_URL='https://www.corecode.io/macupdater/history.html' ## VERSION 1
RELEASE_NOTES_URL='https://www.corecode.io/macupdater/history3.html'

INFO=($(curl -sfL "$XML_FEED" \
		| egrep '(<enclosure.*url="https://.*\.dmg"|sparkle:version=|sparkle:shortVersionString=)' \
		| head -3 \
		| sort \
		| awk -F'"' '/url|sparkle:version|sparkle:shortVersionString/{print $2}'))

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

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}_${LATEST_BUILD}.dmg"

if [[ "$RELEASE_NOTES_URL" != "" ]]
then
	if (( $+commands[lynx] ))
	then

		( echo -n "$NAME: Release Notes for $INSTALL_TO:t:r Version: " ;
		curl -sfL "$RELEASE_NOTES_URL" | sed '1,/<br>/d; /<br>/,$d' \
		| lynx -dump -nomargins -width=10000 -assume_charset=UTF-8 -pseudo_inlines -stdin \
		| egrep --colour=never -i '[a-z0-9]' ;
		echo "Source: <$RELEASE_NOTES_URL>" ) | tee "$FILENAME:r.txt"

	fi
fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

(cd "$FILENAME:h" ; echo "\nLocal sha256:" ; shasum -a 256 "$FILENAME:t" ) >>| "$FILENAME:r.txt"

echo "$NAME: Mounting $FILENAME:"

MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
	| fgrep -A 1 '<key>mount-point</key>' \
	| tail -1 \
	| sed 's#</string>.*##g ; s#.*<string>##g')

if [[ "$MNTPNT" == "" ]]
then
	echo "$NAME: MNTPNT is empty"
	exit 1
else
	echo "$NAME: MNTPNT is $MNTPNT"
fi

if [[ -e "$INSTALL_TO" ]]
then
		# Quit app, if running
	pgrep -xq "$INSTALL_TO:t:r" \
	&& LAUNCH='yes' \
	&& osascript -e "tell application \"$INSTALL_TO:t:r\" to quit"

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.${INSTALLED_VERSION}_${INSTALLED_BUILD}.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then

		echo "$NAME: failed to move '$INSTALL_TO' to Trash. ('mv' \$EXIT = $EXIT)"

		exit 1
	fi

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

[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"

echo -n "$NAME: Unmounting $MNTPNT: " && diskutil eject "$MNTPNT"

exit 0
#EOF
