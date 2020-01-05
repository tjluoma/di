#!/usr/bin/env zsh -f
# Purpose: Download the latest version of BBAutoComplete from https://c-command.com/bbautocomplete/
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2019-06-17

	# This is where the app will be installed or updated.
if [[ -d '/Volumes/Applications' ]]
then
	INSTALL_TO='/Volumes/Applications/BBAutoComplete.app'
	TRASH="/Volumes/Applications/.Trashes/$UID"
else
	INSTALL_TO='/Applications/BBAutoComplete.app'
	TRASH="/.Trashes/$UID"
fi

[[ ! -w "$TRASH" ]] && TRASH="$HOME/.Trash"

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

TEMPFILE="${TMPDIR-/tmp}/${NAME}.$$.$RANDOM.plist"

FEED='https://c-command.com/versions.plist'

curl -sfLS "$FEED" >| "$TEMPFILE"

EXIT="$?"

[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of '$FEED' failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$TEMPFILE" ]] && echo "$NAME: '$TEMPFILE' does not exist." && exit 0

[[ ! -s "$TEMPFILE" ]] && echo "$NAME: '$TEMPFILE' is zero bytes." && rm -f "$TEMPFILE" && exit 0

LATEST_VERSION=$(sed '1,/<key>com.c-command.BBAutoComplete<\/key>/d; /<\/dict>/,$d' "$TEMPFILE" \
				| awk '/\<key\>Version\<\/key\>/{getline ; print}'  \
				| sed 's#.*<string>##g ; s#</string>##g')

URL=$(sed '1,/<key>com.c-command.BBAutoComplete<\/key>/d; /<\/dict>/,$d' "$TEMPFILE" \
		| awk '/\<key\>DownloadURL\<\/key\>/{getline ; print}' \
		| sed 's#.*<string>##g ; s#</string>##g')

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

if (( $+commands[lynx] ))
then

	RELEASE_NOTES=$(sed '1,/<key>com.c-command.BBAutoComplete<\/key>/d; /<\/dict>/,$d' "$TEMPFILE" \
				| sed '1,/<key>ReleaseNotes<\/key>/d; /<\/string>/,$d' \
				| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin \
				| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin)

	echo "${RELEASE_NOTES}\n\nFeed:\t${FEED}\nURL:\t${URL}" | tee "$FILENAME:r.txt"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

(cd "$FILENAME:h" ; echo "\n\nLocal sha256:" ; shasum -a 256 -p "$FILENAME:t" ) >>| "$FILENAME:r.txt"

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
	mv -vf "$INSTALL_TO" "$TRASH/$INSTALL_TO:t:r.${INSTALLED_VERSION}_${INSTALLED_BUILD}.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then

		echo "$NAME: failed to move '$INSTALL_TO' to '$TRASH'. ('mv' \$EXIT = $EXIT)"

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
