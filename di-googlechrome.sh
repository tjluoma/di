#!/usr/bin/env zsh -f
# Purpose: 	Download and install (but not update) the latest version Google Chrome
#
# From:		Timothy J. Luoma
# Mail:		luomat at gmail dot com
# Date:		2019-08-07; updated to just download on 2025-02-15

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

	# must be in /Applications/ for 1Password
INSTALL_TO='/Applications/Google Chrome.app'

if [[ -e "$INSTALL_TO" ]]
then

	echo "$NAME: Fatal error: Google Chrome is already installed.
	This script can only install, not update, Google Chrome."

	exit 0

fi

	# 2021-01-19 - this is a universal (Intel/Apple Silicon) build
URL='https://dl.google.com/chrome/mac/universal/stable/GGRO/googlechrome.dmg'

	# There is no way, that I know of, to check the current version,
	# so I just download the current version

	# No version number is available, we just want to know what this file is
FILENAME="$HOME/Downloads/GoogleChrome.dmg"

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
else
	echo "$NAME: MNTPNT is $MNTPNT"
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

echo -n "$NAME: Unmounting $MNTPNT: " && diskutil eject "$MNTPNT"

exit 0
#EOF
