#!/usr/bin/env zsh -f
# Purpose: Save space by quickly and losslessly trimming video and audio files
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2019-06-09

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

INSTALL_TO='/Applications/LosslessCut.app'

LC_ALL=C

LATEST_RELEASE_URL_RAW=$(curl -sfLS "https://github.com/mifi/lossless-cut/releases" \
	| tr '"' '\012' \
	| egrep '^/mifi/.*/LosslessCut-mac.dmg$' \
	| head -1)

LATEST_RELEASE_URL=$(echo "https://github.com${LATEST_RELEASE_URL_RAW}")

URL="$LATEST_RELEASE_URL"

LATEST_VERSION=$(echo "${LATEST_RELEASE_URL}" | sed 's#/LosslessCut-mac.dmg##g; s#.*/v##g')

HOMEPAGE="https://github.com/mifi/lossless-cut"

RELEASE_NOTES_URL=$(curl --head -sfLS "https://github.com/mifi/lossless-cut/releases/latest" \
					| awk -F' ' '/^.ocation:/{print $2}' | tr -d '\r')

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

FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${LATEST_VERSION}.dmg"

RELEASE_NOTES_TXT="$FILENAME:r.txt"

if [[ -e "$RELEASE_NOTES_TXT" ]]
then

	cat "$RELEASE_NOTES_TXT"

else

	if (( $+commands[lynx] ))
	then

		( echo "Home:\t${HOMEPAGE}\nURL:\t${URL}\nNotes:\t${RELEASE_NOTES_URL}\nVer:\t${LATEST_VERSION}\n" ;
		curl -sfLS "https://github.com/mifi/lossless-cut/releases/latest" \
		| sed '1,/<div class="markdown-body">/d; /<summary>/,$d' \
		| lynx -dump -width='10000' -display_charset=UTF-8 -assume_charset=UTF-8 -pseudo_inlines -stdin -nomargins \
		| sed 's#^ *##g' ) | tee "$FILENAME:r.txt"

	fi

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

(cd "$FILENAME:h" ; echo "\n\nLocal sha256:" ; shasum -a 256 "$FILENAME:t" ) >>| "$FILENAME:r.txt"

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

[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"

exit 0
#EOF
