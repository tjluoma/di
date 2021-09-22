#!/usr/bin/env zsh -f
# Purpose: download and install the latest version of Timing app (v2)
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2021-06-01

NAME="$0:t:r"

[[ -e "$HOME/.path" ]] && source "$HOME/.path"

[[ -e "$HOME/.config/di/defaults.sh" ]] && source "$HOME/.config/di/defaults.sh"

INSTALL_TO="${INSTALL_DIR_ALTERNATE-/Applications}/Timing.app"

	# sparkle feed
XML_FEED='https://updates.timingapp.com/updates/timing2.xml'

	# local file
TEMPFILE="${TMPDIR-/tmp/}${NAME}.${TIME}.$$.$RANDOM.xml"

	# save feed to local
curl -sfLS "$XML_FEED" > "$TEMPFILE"

	# how many items are in feed?
ITEM_COUNT=$(fgrep '<item>' "$TEMPFILE" | wc -l | tr -dc '[0-9]')

	# get the last <item>
INFO=$(awk "/<item>/{i++}i==${ITEM_COUNT}" "$TEMPFILE")

	# result will be something like 28 Mar 1973
	# date might be +1 due to time zone issues. I've decided not to mind.
PUB_DATE=$(echo "$INFO" | fgrep -i '<pubDate>' | awk '{print $2" "$3" "$4}')

	# 2021-06-01 - is a DMG
URL=$(echo "$INFO" | fgrep '<enclosure ' | tr ' ' '\012' | awk -F'"' '/url/{print $2}')

LATEST_VERSION=$(echo "$INFO" | fgrep '<enclosure ' | tr ' ' '\012' | awk -F'"' '/sparkle:shortVersionString/{print $2}')

LATEST_BUILD=$(echo "$INFO" | fgrep '<enclosure ' | tr ' ' '\012' | awk -F'"' '/sparkle:version/{print $2}')

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

	if [[ ! -w "$INSTALL_TO" ]]
	then
		echo "$NAME: '$INSTALL_TO' exists, but you do not have 'write' access to it, therefore you cannot update it." >>/dev/stderr

		exit 2
	fi

else

	FIRST_INSTALL='yes'
fi

FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${${LATEST_VERSION}// /}_${${LATEST_BUILD}// /}.dmg"

RELEASE_NOTES_TXT="$FILENAME:r.txt"

RELEASE_NOTES_HTML="$FILENAME:r.html"

if [[ -e "$RELEASE_NOTES_TXT" ]]
then

	cat "$RELEASE_NOTES_TXT"

elif [[ -e "$RELEASE_NOTES_HTML" ]]
then

	echo "$NAME: Found '$RELEASE_NOTES_HTML'."

else

	RELEASE_NOTES_HTML=$(echo "$INFO" | sed '1,/CDATA/d; /\]\]/,$d')

	if (( $+commands[html2text.py] ))
	then

			# html2text.py deals better with image URLs
		RELEASE_NOTES=$(echo "$INFO" | sed '1,/CDATA/d; /\]\]/,$d' | html2text.py)

		echo "${RELEASE_NOTES}\n\nPubDate: ${PUB_DATE}\nSource: ${XML_FEED}\nVersion: ${LATEST_VERSION} / ${LATEST_BUILD}\nURL: ${URL}" | tee "$RELEASE_NOTES_TXT"
	else
		echo "$RELEASE_NOTES_HTML" >>| "$RELEASE_NOTES_HTML"
	fi

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

egrep -q '^Local sha256:$' "$FILENAME:r.txt" 2>/dev/null

EXIT="$?"

if [ "$EXIT" = "1" -o ! -e "$FILENAME:r.txt" ]
then
	(cd "$FILENAME:h" ; \
		echo "\n\nLocal sha256:" ; \
		shasum -a 256 "$FILENAME:t" \
	)  >>| "$FILENAME:r.txt"
fi

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
	echo "$NAME: moving old installed version to '$HOME/.Trash'..."
	mv -f "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.${INSTALLED_VERSION}_${INSTALLED_BUILD}.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then

		echo "$NAME: failed to move '$INSTALL_TO' to '$HOME/.Trash'. ('mv' \$EXIT = $EXIT)"

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

