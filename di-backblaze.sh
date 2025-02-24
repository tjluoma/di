#!/usr/bin/env zsh -f
# Purpose: 	Download and install (but not update) Backblaze
#
# From:		Timothy J. Luoma
# Mail:		luomat at gmail dot com
# Date:		2018-10-06
# Verified:	2025-02-24

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

########################################################################################################
#
# 		this section is old/outdated but I didn't want to get rid of it for future reference.
#
# mac_version="5.4.0.246" mac_url="%DEST_HOST%/api/install_backblaze?file=bzinstall-mac-5.4.0.246.zip"
#
# INFO=($(curl -sfLS 'https://secure.backblaze.com/api/clientversion.xml' | awk -F'"' '/mac_version/{print $2" "$4}'))
#
# LATEST_VERSION="$INFO[1]"
#
# URL=$(echo "$INFO[2]" | sed 's#%DEST_HOST%#https://secure.backblaze.com#g')

INSTALL_TO="/Applications/Backblaze.app"

URL='https://secure.backblaze.com/mac/install_backblaze.dmg'

if [[ -e "$INSTALL_TO" ]]
then

	echo "$NAME: This script will install, but not update, Backblaze."
	echo "	Found '$INSTALL_TO'. Exiting."
	exit 0
fi

FILENAME="$HOME/Downloads/Backblaze.dmg"

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

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

echo "$NAME: Opening '$MNTPNT/Backblaze Installer.app' ..."

open -a "$MNTPNT/Backblaze Installer.app"

exit 0
#EOF
