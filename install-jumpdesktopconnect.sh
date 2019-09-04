#!/usr/bin/env zsh -f
# Purpose: Download and install the latest version of Jump Desktop Connect
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2019-09-04

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

	# https://jumpdesktop.com/connect/
	# https://jumpdesktop.com/downloads/connect/mac
URL='https://jumpdesktop.com/downloads/connect/JumpDesktopConnect.dmg'

INSTALL_TO='/Applications/Jump Desktop Connect.app'

if [[ -d "$INSTALL_TO" ]]
then
	echo "$NAME: '$INSTALL_TO' already exists."
	exit 0
fi 	

# FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${LATEST_VERSION}_${LATEST_BUILD}."

FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}.dmg"

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL" 

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

(cd "$FILENAME:h" ; echo "\nLocal sha256:" ; shasum -a 256 -p "$FILENAME:t" ) >>| "$FILENAME:r.txt"

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

if (( $+commands[pkginstall.sh] ))
then

	pkginstall.sh "$MNTPNT/.jdc.sparkle_guided.pkg"

else

	sudo /usr/sbin/installer -verbose -pkg "$MNTPNT/.jdc.sparkle_guided.pkg" -dumplog -target / -lang en 2>&1

fi

exit 0
#EOF
