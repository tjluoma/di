#!/usr/bin/env zsh -f
# Purpose: 	Download and install/update the latest version of https://gitfinder.com
#
# From:		Timothy J. Luoma
# Mail:		luomat at gmail dot com
# Date:		2020-02-21
# Verified:	2025-02-24

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

INSTALL_TO='/Applications/GitFinder.app'

HOMEPAGE='https://gitfinder.com'

XML_FEED='https://zigz.ag/GitFinder/updates/stablecast.xml'

INFO=$(curl -sfLS "$XML_FEED" \
		| fgrep -v 'delta' \
		| tr '\012' ' ')

URL=$(echo "$INFO" | sed 's#.*enclosure url="##g ; s#" .*##g')

RELEASE_NOTES_URL=$(echo "$INFO" | sed 's#.*<sparkle:releaseNotesLink>##g ; s#</sparkle:releaseNotesLink>.*##g')

LATEST_VERSION=$(echo "$INFO" | sed 's#.*<sparkle:shortVersionString>##g ; s#</sparkle:shortVersionString>.*##g')

LATEST_BUILD=$(echo "$INFO" | sed 's#.*<sparkle:version>##g ; s#</sparkle:version>.*##g' )

	# If any of these are blank, we cannot continue
if [ "$INFO" = "" -o "$LATEST_BUILD" = "" -o "$URL" = "" -o "$LATEST_VERSION" = "" ]
then
	echo "$NAME: Error: bad data received:
	INFO: $INFO
	RELEASE_NOTES_URL: $RELEASE_NOTES_URL
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

	if [[ ! -w "$INSTALL_TO" ]]
	then
		echo "$NAME: '$INSTALL_TO' exists, but you do not have 'write' access to it, therefore you cannot update it." >>/dev/stderr

		exit 2
	fi

else

	FIRST_INSTALL='yes'
fi

FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${${LATEST_VERSION}// /}_${${LATEST_BUILD}// /}.dmg"

if (( $+commands[lynx] ))
then
	if [[ -e "$FILENAME:r.txt" ]]
	then

		cat "$FILENAME:r.txt"

	else

		RELEASE_NOTES=$(curl -sfLS "$RELEASE_NOTES_URL" \
						| lynx -dump -nomargins -width='10000' -display_charset=UTF-8 -assume_charset=UTF-8 -pseudo_inlines -stdin)

		echo "${RELEASE_NOTES}\n\nSource: ${RELEASE_NOTES_URL}\nVersion : ${LATEST_VERSION} / ${LATEST_BUILD}\nURL: $URL" | tee "$FILENAME:r.txt"

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

echo "$NAME: Accepting the EULA and mounting '$FILENAME':"

MNTPNT=$(echo -n "Y" | hdid -plist "$FILENAME" 2>/dev/null | fgrep '/Volumes/' | sed 's#</string>##g ; s#.*<string>##g')

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
