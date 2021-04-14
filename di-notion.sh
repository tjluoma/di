#!/usr/bin/env zsh -f
# Purpose: Download and install/update the latest version of https://www.notion.so
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2019-12-11

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

	# NOT XML
FEED='https://desktop-release.notion-static.com/latest-mac.yml'

INSTALL_TO='/Applications/Notion.app'

TEMPFILE="${TMPDIR-/tmp}/${NAME}.${TIME}.$$.$RANDOM.yml"

curl -sfLS "$FEED" >| "$TEMPFILE"

LATEST_VERSION=$(awk -F' ' '/^version/{print $NF}' "$TEMPFILE")

[[ "$LATEST_VERSION" == "" ]] \
&& echo "$NAME: 'LATEST_VERSION' is empty. See '$TEMPFILE'." \
&& exit 1

	# There is also a zip version, but it seems like some kind of weird zip
	# that confuses some CL tools, so I'm sticking with the DMG
REMOTE_FILENAME=$(awk -F' ' '/\.dmg/{print $NF}' "$TEMPFILE")

[[ "$REMOTE_FILENAME" == "" ]] \
&& echo "$NAME: 'REMOTE_FILENAME' is empty. See '$TEMPFILE'." \
&& exit 1

URL=$(echo "https://desktop-release.notion-static.com/$REMOTE_FILENAME")

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleShortVersionString)

	autoload is-at-least

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	VERSION_COMPARE="$?"

	if [ "$VERSION_COMPARE" = "0" ]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION)"
		exit 0
	fi

	echo "$NAME: Outdated: $INSTALLED_VERSION vs $LATEST_VERSION"

	FIRST_INSTALL='no'

else

	FIRST_INSTALL='yes'
fi

FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${${LATEST_VERSION}// /}.dmg"

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
