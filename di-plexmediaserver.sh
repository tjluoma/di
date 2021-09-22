#!/usr/bin/env zsh -f
# Purpose: download and install the latest version of Plex Media Server
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2020-06-05

NAME="$0:t:r"

[[ -e "$HOME/.path" ]] && source "$HOME/.path"

[[ -e "$HOME/.config/di/defaults.sh" ]] && source "$HOME/.config/di/defaults.sh"

INSTALL_TO="${INSTALL_DIR_ALTERNATE-/Applications}/Plex Media Server.app"

zmodload zsh/datetime

TIME=$(strftime "%Y-%m-%d--%H.%M.%S" "$EPOCHSECONDS")

	# define a temp file where we can store the json so we
	# don't have to retrieve it multiple times from the web
TEMPFILE="${TMPDIR-/tmp/}${NAME}.${TIME}.$$.$RANDOM.json"

	# make sure tempfile doesn't exist
rm -f "$TEMPFILE"

	# save json to tempfile
curl -sfLS 'https://plex.tv/api/downloads/5.json' > "$TEMPFILE"

	# do some very rough 'parsing' of json with 'sed'
	# this would be easier if we could assume `jq` is installed
	# but we can't
INFO=$(sed -e 's#.*"MacOS"##g' -e 's#},.*##g' -e 's#","#"\
"#g' "$TEMPFILE")

	# Extract URL from $INFO
URL=$(echo "$INFO" | awk -F'"' '/^"url":/{print $4}')

	# Extract Version from $INFO - note that the version number here
	# has extra stuff that is not in the version number of the app
	# which is terrible and no one should ever do that
	# but they did that .
LATEST_VERSION=$(echo "$INFO" | awk -F'"' '/"version":/{print $6}' | sed 's#-.*##g')

	# If any of these are blank, we cannot continue
if [ "$INFO" = "" -o "$URL" = "" -o "$LATEST_VERSION" = "" ]
then
	echo "$NAME: Error: bad data received:
	INFO: $INFO
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	"  >>/dev/stderr

	exit 2
fi

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleVersion)

	autoload is-at-least

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	VERSION_COMPARE="$?"

	if [ "$VERSION_COMPARE" = "0" ]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION / $LATEST_VERSION)"
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

FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${${LATEST_VERSION}// /}.zip"

RELEASE_NOTES_TXT="$FILENAME:r.txt"

if [[ -e "$RELEASE_NOTES_TXT" ]]
then

	cat "$RELEASE_NOTES_TXT"

else

		# we often require `lynx` for release notes even though it isn't installed
		# by default, but this time we need `jq`

	if (( $+commands[jq] ))
	then

		EXTRA_INFO=$(jq -r .computer.MacOS.extra_info "$TEMPFILE")

		ADDED=$(jq -r .computer.MacOS.items_added "$TEMPFILE")

		FIXED=$(jq -r .computer.MacOS.items_fixed "$TEMPFILE")

		RELEASE_TIME_EPOCH=$(jq -r .computer.MacOS.release_date "$TEMPFILE")

		RELEASE_TIME_READABLE=$(strftime "%Y/%m/%d at %H:%M:%S" ${RELEASE_TIME_EPOCH})

		if [[ "${EXTRA_INFO}" != "" ]]
		then
			EXTRA_INFO="## Extra Info:\n\n${EXTRA_INFO}\n\n"
		fi

		if [[ "${ADDED}" != "" ]]
		then
			ADDED="## Added:\n\n${ADDED}\n\n"
		fi

		if [[ "${FIXED}" != "" ]]
		then
			FIXED="## Fixed:\n\n${FIXED}\n\n"
		fi

		RELEASE_NOTES=$(echo "# Plex Media Server\n\n${EXTRA_INFO}${ADDED}${FIXED}\n\nReleased Date: ${RELEASE_TIME_READABLE}")

		echo "${RELEASE_NOTES}\n\nVersion: ${LATEST_VERSION}\nURL: ${URL}" | tee "$RELEASE_NOTES_TXT"

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

TRASH="$HOME/.Trash"

	## make sure that the .zip is valid before we proceed
(command unzip -l "$FILENAME" 2>&1 )>/dev/null

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: '$FILENAME' is a valid zip file."

else
	echo "$NAME: '$FILENAME' is an invalid zip file (\$EXIT = $EXIT)"

	mv -fv "$FILENAME" "$HOME/.Trash/"

	mv -fv "$FILENAME:r".* "$HOME/.Trash/"

	exit 0

fi

	## unzip to a temporary directory
UNZIP_TO=$(mktemp -d "$HOME/.Trash/${NAME}-XXXXXXXX")

echo "$NAME: Unzipping '$FILENAME' to '$UNZIP_TO':"

ditto -xk --noqtn "$FILENAME" "$UNZIP_TO"

EXIT="$?"

if [[ "$EXIT" == "0" ]]
then
	echo "$NAME: Unzip successful"
else
		# failed
	echo "$NAME failed (ditto -xkv '$FILENAME' '$UNZIP_TO')"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	pgrep -xq "$INSTALL_TO:t:r" \
	&& LAUNCH='yes' \
	&& osascript -e "tell application \"$INSTALL_TO:t:r\" to quit"

	echo "$NAME: Moving existing (old) '$INSTALL_TO' to '$HOME/.Trash/'."

	mv -f "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then

		echo "$NAME: failed to move existing '$INSTALL_TO' to '$HOME/.Trash'."

		exit 1
	fi
fi

echo "$NAME: Moving new version of '$INSTALL_TO:t' (from '$UNZIP_TO') to '$INSTALL_TO'."

	# Move the file out of the folder
mv -n "$UNZIP_TO/$INSTALL_TO:t" "$INSTALL_TO"

EXIT="$?"

if [[ "$EXIT" = "0" ]]
then

	echo "$NAME: Successfully installed '$UNZIP_TO/$INSTALL_TO:t' to '$INSTALL_TO'."

else
	echo "$NAME: Failed to move '$UNZIP_TO/$INSTALL_TO:t' to '$INSTALL_TO'."

	exit 1
fi

[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"

exit 0
#EOF
