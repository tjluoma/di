#!/bin/zsh -f
# Purpose: Download and install the latest version of Suspicious Package
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-07-19

NAME="$0:t:r"

INSTALL_TO='/Applications/Suspicious Package.app'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

	# Note the URL is a plist not your ususal RSS/XML file for Sparkle
INFO=$(curl -sfL "http://www.mothersruin.com/software/SuspiciousPackage/data/SuspiciousPackageVersionInfo.plist")

LATEST_VERSION=$(echo "$INFO" | fgrep -A1 "<key>CFBundleShortVersionString</key>" | tr -dc '[0-9]\.')

LATEST_BUILD=$(echo "$INFO" | fgrep -A1 "<key>CFBundleVersion</key>" | tr -dc '[0-9]\.')

	# $INFO does not contain any download URLs
URL='http://www.mothersruin.com/software/downloads/SuspiciousPackage.dmg'

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
		echo "$NAME: Up To Date ($INSTALLED_VERSION/$INSTALLED_BUILD)"
		exit 0
	else
		echo "$NAME: Outdated: $INSTALLED_VERSION/$INSTALLED_BUILD vs $LATEST_VERSION/$LATEST_BUILD"
	fi

	FIRST_INSTALL='no'
else

	FIRST_INSTALL='yes'
fi

FILENAME="$HOME/Downloads/SuspiciousPackage-${LATEST_VERSION}-${LATEST_BUILD}.dmg"

echo "$NAME: Downloading \"$URL\" to \"$FILENAME\":"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

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

if [[ -e "$INSTALL_TO" ]]
then
		# Quit app, if running
	pgrep -xq "$INSTALL_TO:t:r" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "$INSTALL_TO:t:r" to quit'

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"
fi

echo "$NAME installing \"$MNTPNT/$INSTALL_TO:t\" to \"$INSTALL_TO\":"

ditto --noqtn "$MNTPNT/$INSTALL_TO:t" "$INSTALL_TO"

EXIT="$?"

if [ "$EXIT" = "0" ]
then

	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleShortVersionString)

	INSTALLED_BUILD=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleVersion)

	echo "$NAME: Successfully installed $INSTALL_TO:t ($INSTALLED_VERSION/$INSTALLED_BUILD)"

else
	echo "$NAME: 'ditto' failed (\$EXIT = $EXIT)"

	exit 1
fi

	# We need to launch the app at least once in order to use its QuickLook plugins
if [[ "$FIRST_INSTALL" == 'yes' ]]
then

	echo "$NAME: This is the first time we have installed $INSTALL_TO. Launching app to force it to register its QuickLook plugins."

	open -a "$INSTALL_TO"

fi

if (( $+commands[unmount.sh] ))
then
	unmount.sh "$MNTPNT"
else
	diskutil eject "$MNTPNT"
fi


exit 0
#
#EOF
