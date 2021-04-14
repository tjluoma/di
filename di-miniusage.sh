#!/usr/bin/env zsh -f
# Purpose: MiniUsage displays various data like CPU usage, amount of network flow, battery status and process names which uses much CPU time in a menubar.
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2019-09-28

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

INSTALL_TO='/Applications/MiniUsage.app'

HOMEPAGE='http://nsek.net/SYW/software/english/miniusage/'

DOWNLOAD='http://nsek.net/SYW/software/english/miniusage/download.html'

URL='http://nsek.net/SYW/software/download/MiniUsage.dmg'

	## Note: this 'LC_ALL' syntax appears to be wrong (shasum doesn't like it),
	## but it does prevent sed from complaining about 'illegal byte sequence'
	## and setting it to 'en_US.UTF-8' does not seem to work for some reason,
	## so I'm going to leave it here for this command…
LC_ALL=UTF=8 INFO=($(curl -sfLS "http://nsek.net/SYW/software/english/miniusage/" \
		| sed '1,/Version History/d' \
		| awk '/<tr /{i++}i==1' \
		| sed 's#<img src="../../parts/shim.gif" width="73" height="8" border="0">##g'  \
		| tr -d '\012'))

	## …but then I make sure to reset 'LC_ALL' to something more reasonable and correct
LC_ALL=en_US.UTF-8

LATEST_VERSION=$(echo "$INFO" | sed 's#.*<td width="50">##g ; s#</td>.*##g')

if [[ "$LATEST_VERSION" == "" ]]
then
	echo "$NAME: '\$LATEST_VERSION' is empty. Web-scraping appears to have failed."
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

	DATE=$(echo "$INFO" | sed 's#.*<td width="65">#20#g ; s#</td>.*##g')

	RELEASE_NOTES=$(echo "$INFO" \
				| sed 's#.*</td><td>##g ; s#</td></tr>##g' \
				| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin -nonumbers -nolist)

	echo "Mini Usage Version $LATEST_VERSION (Last Updated: $DATE)\n\n$RELEASE_NOTES" | tee "$FILENAME:r.txt"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

(cd "$FILENAME:h" ; echo "\nLocal sha256:" ; shasum -a 256 "$FILENAME:t" ) >>| "$FILENAME:r.txt"

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

if [[ -d "$MNTPNT/MiniUsage/MiniUsage.app" ]]
then

	SOURCE="$MNTPNT/MiniUsage/MiniUsage.app"

elif [[ -d "$MNTPNT/MiniUsage.app" ]]
then

	SOURCE="$MNTPNT/MiniUsage.app"

else

	echo "$NAME: Failed to find 'MiniUsage.app' in '$MNTPNT'."
	exit 1

fi

echo "$NAME: Installing '$SOURCE' to '$INSTALL_TO': "

ditto --noqtn -v "$SOURCE" "$INSTALL_TO"

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
