#!/usr/bin/env zsh -f
# Purpose: Download and install the latest version of Rectangle.app from https://rectangleapp.com
#
# From:		Timothy J. Luoma
# Mail:		luomat at gmail dot com
# Date:		2020-07-01
# Verified:	2025-02-15

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

INSTALL_TO='/Applications/Rectangle.app'

XML_FEED='https://rectangleapp.com/downloads/updates.xml'

INFO=$(curl -sfLS "$XML_FEED" \
| fgrep -vi 'delta' \
| tr -s '\n|\r|\t| ' ' ' \
| sed -e 's#<item>#\
<item>#g' \
| fgrep '<item>' \
| head -1 \
| sed -e 's#</item>.*##g'  )

URL=$(echo "$INFO" \
	| sed -e 's#.*url="##g' -e 's#" .*##g' )

LATEST_VERSION=$(echo "$INFO" \
	| sed 	-e 's#.*<sparkle:shortVersionString>##g' \
			-e 's#</sparkle:shortVersionString>.*##g' )

LATEST_BUILD=$(echo "$INFO" \
	| sed 	-e 's#.*<sparkle:version>##g' \
			-e 's#</sparkle:version>.*##g' )

RELEASE_NOTES_HTML=$(echo "$INFO" | sed -e 's#\]\]\>.*##g' -e 's#.*\[CDATA\[##g')

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

if [[ -e "$RELEASE_NOTES_TXT" ]]
then

	cat "$RELEASE_NOTES_TXT"

else

	if (( $+commands[lynx] ))
	then

		RELEASE_NOTES=$(echo "$RELEASE_NOTES_HTML"  \
			| lynx -dump -width='10000' -display_charset=UTF-8 -assume_charset=UTF-8 -pseudo_inlines -stdin -nomargins)

		echo "$INSTALL_TO:t Changelog:\n\n${RELEASE_NOTES}\n\nSource: ${XML_FEED}\nVersion : ${LATEST_VERSION} / ${LATEST_BUILD}\nURL: $URL\n" \
		| tee "$RELEASE_NOTES_TXT"

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
