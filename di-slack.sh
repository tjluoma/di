#!/bin/zsh -f
# Purpose: Download the direct (not Mac App Store) version of Slack from <https://slack.com>
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-12-17

NAME="$0:t:r"

INSTALL_TO='/Applications/Slack.app'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

	# ".ocation" takes care of Location: or location:
URL=$(curl -sfL --head "https://slack.com/ssb/download-osx" \
		| awk -F' |\r' '/^.ocation: /{print $2}' \
		| tail -1 )

LATEST_VERSION=$(echo "$URL:t:r" | tr -dc '[0-9]\.')

if [ "$LATEST_VERSION" = "" -o "$URL" = "" ]
then
	echo "$NAME: Error: bad data received
	URL: $URL
	LATEST_VERSION: $LATEST_VERSION
	"
	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo '0'`

	if [[ "$LATEST_VERSION" == "$INSTALLED_VERSION" ]]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION)"
		exit 0
	fi

	autoload is-at-least

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	if [ "$?" = "0" ]
	then
		echo "$NAME: Installed version ($INSTALLED_VERSION) is ahead of official version $LATEST_VERSION"
		exit 0
	fi

	echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"

fi

if (( $+commands[lynx] ))
then
	RELEASE_NOTES_URL='https://slack.com/release-notes/mac'

	echo -n "$NAME: Release Notes for "

	curl -sfL "${RELEASE_NOTES_URL}" \
	| sed '1,/<a name="/d; /<a name="/,$d' \
	| lynx -dump -nomargins -nonumbers -width=10000 -assume_charset=UTF-8 -pseudo_inlines -nolist -stdin \
	| sed '/./,/^$/!d'

	# last line: sed remove blank lines from start

	echo "\nSource: <$RELEASE_NOTES_URL>"

fi

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}.dmg"

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

echo "$NAME: Mounting $FILENAME:"

MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
	| fgrep -A 1 '<key>mount-point</key>' \
	| tail -1 \
	| sed 's#</string>.*##g ; s#.*<string>##g')

if [[ "$MNTPNT" == "" ]]
then
	echo "$NAME: MNTPNT is empty"
	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then
		# Quit app, if running
	pgrep -xq "$INSTALL_TO:t:r" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "$INSTALL_TO:t:r" to quit'

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.${INSTALLED_VERSION}_${INSTALLED_BUILD}.app"
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

echo "$NAME: Unmounting $MNTPNT:"

diskutil eject "$MNTPNT"

exit 0
#EOF
