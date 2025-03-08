#!/usr/bin/env zsh -f
# Purpose: 	Download and install the latest version of BBEdit
#
# From:		Timothy J. Luoma
# Mail:		luomat at gmail dot com
# Date:		2021-05-04
# Verified:	2025-02-16 (for clean install)

NAME="$0:t:r"

[[ -e "$HOME/.path" ]] && source "$HOME/.path"

[[ -e "$HOME/.config/di/defaults.sh" ]] && source "$HOME/.config/di/defaults.sh"

INSTALL_TO="${INSTALL_DIR_ALTERNATE-/Applications}/BBEdit.app"

	# if this file exists (regardless of size or content, just exists)
	# it will be assumed that the user wants to use beta versions of BBEdit
PREFERS_BETA="$HOME/.config/di/prefers/BBEdit-prefer-betas.txt"

if [[ -e "$PREFERS_BETA" ]]
then
		# @todo - next time there is a beta, double check this is correct
	# XML_FEED='https://versioncheck.barebones.com/BBEdit-414.xml'
	XML_FEED='https://versioncheck.barebones.com/BBEdit-415.xml'

	echo "$NAME: Don't know what to use for 'RELEASE_NOTES_URL'" >>/dev/stderr

	RELEASE_NOTES_URL=''

else
	XML_FEED='https://versioncheck.barebones.com/BBEdit.xml'
	RELEASE_NOTES_URL='https://www.barebones.com/support/bbedit/current_notes.html'
fi

zmodload zsh/datetime

TIME=$(strftime "%Y-%m-%d--%H.%M.%S" "$EPOCHSECONDS")

function timestamp { strftime "%Y-%m-%d--%H.%M.%S" "$EPOCHSECONDS" }

PLIST="${TMPDIR-/tmp/}${NAME}.${TIME}.$$.$RANDOM.plist"

curl -sfLS "$XML_FEED" \
| sed -e '1,/<array>/d' -e '/<\/array>/,$d' \
| tr -d '\t|\r\n' \
| sed 's#<dict>#\
<dict>#g' \
| tail -1 > "${PLIST}"

LATEST_BUILD=$(defaults read "${PLIST}" SUFeedEntryVersion)

LATEST_VERSION=$(defaults read "${PLIST}" SUFeedEntryShortVersionString)

URL=$(defaults read "${PLIST}" SUFeedEntryDownloadURL)

MIN_VERSION=$(defaults read "${PLIST}" SUFeedEntryMinimumSystemVersion)

OS_VER=$(sw_vers -productVersion)

autoload is-at-least

is-at-least "$MIN_VERSION" "$OS_VER"

EXIT="$?"

if [[ "$EXIT" != "0" ]]
then
	echo "$NAME: BBEdit version $LATEST_VERSION/$LATEST_BUILD requires '$MIN_VERSION' and you are running '$OS_VER'." >>/dev/stderr
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

CHECKSUM_FILE="$FILENAME:r.sha256.txt"

############################################################################################################

if [[ "$RELEASE_NOTES_URL" != "" ]]
then

	if (( $+commands[wget] ))
	then

		RELEASE_NOTES_FILE="$FILENAME:r.html"

		if [[ -e "$RELEASE_NOTES_FILE" ]]
		then

			echo "$NAME: '$RELEASE_NOTES_FILE' already exists"

		else

			echo "$NAME: saving Release Notes to '$RELEASE_NOTES_FILE' (this may take a moment)."

			wget --quiet --convert-links --output-document="$RELEASE_NOTES_FILE" "$RELEASE_NOTES_URL"

		fi

	fi # if wget

fi # if RELEASE_NOTES_URL

############################################################################################################

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

egrep -q '^Local sha256:$' "$CHECKSUM_FILE" 2>/dev/null

EXIT="$?"

if [ "$EXIT" = "1" -o ! -e "$CHECKSUM_FILE" ]
then
	(cd "$FILENAME:h" ; \
	echo "\nLocal sha256:" ; \
	shasum -a 256 "$FILENAME:t" \
	)  >>| "$CHECKSUM_FILE"
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
