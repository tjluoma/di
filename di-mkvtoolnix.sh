#!/usr/bin/env zsh -f
# Purpose:
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2019-06-23

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

INSTALL_TO='/Applications/MKVToolNix.app'

	# This URL isn't a real URL. We just need it for the version number
	# but we can't use the end-result, because the fosshub.com website is
	# so terrible
URL=$(curl -sfLS "https://www.fosshub.com/MKVToolNix.html" | tr '"' '\012' | egrep '^http.*\.dmg')

LATEST_VERSION=$(echo "$URL:t:r" | sed 's#MKVToolNix.html?dwl=MKVToolNix-##g')

	# We can actually download from this URL
URL="https://mkvtoolnix.download/macos/MKVToolNix-${LATEST_VERSION}.dmg"

FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${LATEST_VERSION}.dmg"

RELEASE_NOTES_URL="https://mkvtoolnix.download/doc/NEWS.md"

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

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

(curl -sfLS "$RELEASE_NOTES_URL" | awk '/^# Version/{i++}i==1' ) | tee "$FILENAME:r.txt"

(cd "$FILENAME:h" ; echo "\n\nURL:\t${URL}\nLocal sha256:" ; shasum -a 256 "$FILENAME:t" ) >>| "$FILENAME:r.txt"

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
fi

MNT_APP=$(find "$MNTPNT" -maxdepth 1 -iname '*.app' -print | head -1)

if [[ "$MNT_APP" == "" ]]
then
	echo "$NAME: '$MNT_APP' is empty"
	exit 1
fi

echo "$NAME: Installing '$MNT_APP' to '$INSTALL_TO': "

ditto --noqtn -v "$MNT_APP" "$INSTALL_TO"

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
