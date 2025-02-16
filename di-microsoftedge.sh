#!/usr/bin/env zsh -f
# Purpose: 	Get the latest arm64 build of Microsoft Edge (but NOT Microsoft AutoUpdate)
#
# From:		Timothy J. Luoma
# Mail:		luomat at gmail dot com
# Date:		2022-03-15
# Verified:	2025-02-15

INSTALL_TO='/Applications/Microsoft Edge.app'

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

URL=$(curl -sfLS --head "https://go.microsoft.com/fwlink/?linkid=2093504&platform=Mac&Consent=1&channel=Stable" \
	| egrep -i '^Location: ' \
	| sed -e 's#^Location: ##g' -e 's#.$##g')

SHORTNAME=$(echo "$URL:t" | sed 's#\.pkg.*#.pkg#g')

LATEST_VERSION=$(echo "$SHORTNAME:t:r" | sed -e 's#MicrosoftEdge-##g' )

	# If any of these are blank, we cannot continue
if [ "$URL" = "" -o "$LATEST_VERSION" = ""  ]
then
	echo "$NAME: Error: bad data received:
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	"  >>/dev/stderr

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleShortVersionString)

	autoload is-at-least

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	VERSION_COMPARE="$?"

	if [ "$VERSION_COMPARE" = "0" ]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION/$LATEST_VERSION)"
		exit 0
	fi

	echo "$NAME: Outdated: $INSTALLED_VERSION vs $LATEST_VERSION"

	FIRST_INSTALL='no'

	if [[ ! -w "$INSTALL_TO" ]]
	then
		echo "$NAME: '$INSTALL_TO' exists, but you do not have 'write' access to it, therefore you cannot update it." >>/dev/stderr

		exit 2
	fi

else

	FIRST_INSTALL='yes'
fi

FILENAME="${DOWNLOAD_DIR_ALTERNATE-$HOME/Downloads}/${${INSTALL_TO:t:r}// /}-${${LATEST_VERSION}// /}.pkg"

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

TEMP_DIR="${TMPDIR-/tmp/}${NAME-$0:r}-$RANDOM"

pkgutil --expand "$FILENAME" "$TEMP_DIR"

PAYLOAD_FILE=$(find ${TEMP_DIR}/MicrosoftEdge-*.pkg -iname Payload -print)

echo "PAYLOAD_FILE is >$PAYLOAD_FILE<"

cd "$TEMP_DIR"

echo "$NAME [INFO]: Uncompressing '$PAYLOAD_FILE' in '$TEMP_DIR'... "

gunzip --force --stdout "$PAYLOAD_FILE" | cpio -i

sudo xattr -r -d com.apple.quarantine "$INSTALL_TO:t" || false


################################################################################################

if [[ -e "$INSTALL_TO" ]]
then

	pgrep -xq "$INSTALL_TO:t:r" \
	&& LAUNCH='yes' \
	&& osascript -e "tell application \"$INSTALL_TO:t:r\" to quit"

	MOVE_TO="$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"

	echo "$NAME: Moving existing (old) '$INSTALL_TO' to '$MOVE_TO/'."

	mv -f "$INSTALL_TO" "$MOVE_TO"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then

		echo "$NAME: failed to move existing '$INSTALL_TO' to '$MOVE_TO'." >>/dev/stderr

		exit 2
	fi
fi

################################################################################################

echo "$NAME: Moving new version of '$INSTALL_TO:t' (from '$TEMP_DIR') to '$INSTALL_TO'."

	# Move the file out of the folder
mv -n "$TEMP_DIR/$INSTALL_TO:t" "$INSTALL_TO"

EXIT="$?"

if [[ "$EXIT" = "0" ]]
then

	echo "$NAME: Successfully installed '$TEMP_DIR/$INSTALL_TO:t' to '$INSTALL_TO'."

else
	echo "$NAME: Failed to move '$TEMP_DIR/$INSTALL_TO:t' to '$INSTALL_TO'."

	exit 1
fi

[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"

exit 0
#EOF
