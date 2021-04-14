#!/usr/bin/env zsh -f
# Purpose: Ever wondered if an application records audio through your Mac’s built-in microphone without your knowledge? Or if the camera captures video for no good reason?
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2019-02-16

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

INSTALL_TO='/Applications/Micro Snitch.app'

PLIST_URL="https://sw-update.obdev.at/update-feeds/microsnitch-1.plist"

zmodload zsh/datetime

TIME=`strftime "%Y-%m-%d--%H.%M.%S" "$EPOCHSECONDS"`

function timestamp { strftime "%Y-%m-%d--%H.%M.%S" "$EPOCHSECONDS" }

TEMPFILE="${TMPDIR-/tmp}/${NAME}.${TIME}.$$.$RANDOM.plist"

curl -sfLS "$PLIST_URL" > "$TEMPFILE"

## DON'T INDENT
INFO=($(cat "$TEMPFILE" \
| tr -d '\t|\n' \
| sed -e 's#</dict><dict>.*##g' -e 's#.*<array><dict>##g' -e 's#</string><key>#\
#g' -e 's#</key><string># #g' -e 's#</string></dict><key>#\
#g' -e 's#</key><dict><key>#\
#g' -e 's#</string>##g' -e 's#<key>##g' \
| sort \
| egrep '^(BundleVersion|BundleShortVersionString|ReleaseNotesURL|DownloadURL) ' \
| awk '{print $NF}'))
## END - DON'T INDENT

LATEST_VERSION="$INFO[1]"

LATEST_BUILD="$INFO[2]"

URL="$INFO[3]"

RELEASE_NOTES_URL="$INFO[4]"

# echo "
# LATEST_VERSION: $LATEST_VERSION
# LATEST_BUILD: $LATEST_BUILD
# URL: $URL
# RELEASE_NOTES_URL: $RELEASE_NOTES_URL
#
# "

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

else

	FIRST_INSTALL='yes'
fi

FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${LATEST_VERSION}_${LATEST_BUILD}.zip"

if (( $+commands[lynx] ))
then

	lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines "$RELEASE_NOTES_URL" | tee "$FILENAME:r.txt"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

echo "\nURL: ${URL}" >>| "$FILENAME:r.txt"

(cd "$FILENAME:h" ; echo "\nLocal sha256:" ; shasum -a 256 "$FILENAME:t" ) >>| "$FILENAME:r.txt"

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
UNZIP_TO=$(mktemp -d "${TMPDIR-/tmp/}${NAME}-XXXXXXXX")

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

	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then

		echo "$NAME: failed to move existing $INSTALL_TO to $HOME/.Trash/"

		exit 1
	fi
fi

echo "$NAME: Moving new version of '$INSTALL_TO:t' (from '$UNZIP_TO') to '$INSTALL_TO'."

	# Move the file out of the folder
mv -vn "$UNZIP_TO/$INSTALL_TO:t" "$INSTALL_TO"

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

# https://obdev.at/products/microsnitch/download.html
# https://obdev.at/products/microsnitch/download-legacy.html
