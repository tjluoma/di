#!/bin/zsh -f
# Purpose: Download and install the last _non Mac App Store_ version of ScreenSharingMenulet
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-09-04

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

# http://www.klieme.com/Downloads/ScreenSharingMenulet/appcast.xml exists, but the download URL is 404

INSTALL_TO='/Applications/ScreenSharingMenulet 2.2.app'
URL='https://www.dropbox.com/s/2nasflslxhrz3lt/ScreenSharingMenulet-2.2_200.dmg?dl=0'
LATEST_VERSION="2.2"
LATEST_BUILD="200"
RELEASE_NOTES_URL='http://www.klieme.com/ScreenSharingMenulet.html'
HOMEPAGE="http://www.klieme.com/ScreenSharingMenulet.html"
ITUNES_URL='itunes.apple.com/us/app/screensharingmenulet/id578078659'
DOWNLOAD_PAGE="https://itunes.apple.com/us/app/screensharingmenulet/id578078659?mt=12"
MAS_URL='macappstore://itunes.apple.com/us/app/screensharingmenulet/id578078659'
SUMMARY="Connect to local, Back to My Mac, and custom hosts via Screen Sharing from the menu bar. (Note: a newer version is available in the Mac App Store.)"

ALT_INSTALL_TO='/Applications/ScreenSharingMenulet.app'

cat <<EOINPUT

$NAME: NOTE!

This script can only install version 2.2.

The newest version of this app is 2.8, and is available only from the Mac App Store.

See <$DOWNLOAD_PAGE> or <$MAS_URL> for more information.

EOINPUT

if (( $+commands[mas] ))
then
	echo "If you have previously purchased ScreenSharingMenulet from the Mac App Store, you can install it via:"
	echo "	mas install 578078659"
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
		echo "$NAME: See <$DOWNLOAD_PAGE> for newer, Mac App Store-only version."
		exit 0
	fi

	echo "$NAME: Outdated: $INSTALLED_VERSION/$INSTALLED_BUILD vs $LATEST_VERSION/$LATEST_BUILD"

fi

if [[ -e "$ALT_INSTALL_TO" ]]
then

	INSTALLED_VERSION=$(defaults read "${ALT_INSTALL_TO}/Contents/Info" CFBundleShortVersionString)

	INSTALLED_BUILD=$(defaults read "${ALT_INSTALL_TO}/Contents/Info" CFBundleVersion)

	autoload is-at-least

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	VERSION_COMPARE="$?"

	is-at-least "$LATEST_BUILD" "$INSTALLED_BUILD"

	BUILD_COMPARE="$?"

	if [ "$VERSION_COMPARE" = "0" -a "$BUILD_COMPARE" = "0" ]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION/$INSTALLED_BUILD)"
		echo "$NAME: See <$DOWNLOAD_PAGE> for newer, Mac App Store-only version."
		exit 0
	fi

	if [[ -e "$INSTALL_TO/Contents/_MASReceipt/receipt" ]]
	then
		echo "$NAME: $INSTALL_TO was installed from the Mac App Store and cannot be updated by this script."

		if [[ "$ITUNES_URL" != "" ]]
		then
			echo "	See <https://$ITUNES_URL?mt=12> or"
			echo "	<macappstore://$ITUNES_URL>"
		fi

		echo "	Please use the App Store app to update it: <macappstore://showUpdatesPage?scan=true>"
		exit 0
	fi

	echo "$NAME: Outdated: $INSTALLED_VERSION/$INSTALLED_BUILD vs $LATEST_VERSION/$LATEST_BUILD"

	# if we get here, we have found the app at $ALT_INSTALL_TO but it is NOT the Mac App Store version
	# so we want to update the app at $ALT_INSTALL_TO instead of installing it at the original $INSTALL_TO

	INSTALL_TO="$ALT_INSTALL_TO"

	echo "$NAME: Note! We are using '$INSTALL_TO' since we found an existing (non-Mac App Store) installation there."

fi

	# note: hard-coding name because we don't want potential confusion or spaces in the filename
FILENAME="$HOME/Downloads/ScreenSharingMenulet-${LATEST_VERSION}_${LATEST_BUILD}.dmg"

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

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
else
	echo "$NAME: MNTPNT is $MNTPNT"
fi

if [[ -e "$INSTALL_TO" ]]
then
		# Quit app, if running
	pgrep -xq "$INSTALL_TO:t:r" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "$INSTALL_TO:t:r" to quit'

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.${INSTALLED_VERSION}_${INSTALLED_BUILD}.app"
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
