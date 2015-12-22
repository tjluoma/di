#!/bin/zsh -f
# Purpose: Download and install latest version of MakeMKV.app
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-12-21

NAME="$0:t:r"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

########################################################################################################################
	## I can't seem to find an RSS feed for the updates, although it does have some sort of update checking
	## So, instead, I make an ugly-hack-ish check for an URL with 'dmg' in it 
URL=`curl -sfL 'http://www.makemkv.com/download/' \
	| tr '\047|"' '\012' \
	| egrep 'http.*\.dmg' \
	| head -1`

if [[ "$URL" == "" ]]
then
	echo "$NAME: Error: URL is empty"
	exit 0
fi

LATEST_VERSION=`echo "$URL:t:r" | tr -dc '[0-9].'`

	# If any of these are blank, we should not continue
if [[ "$LATEST_VERSION" == "" ]]
then
	echo "$NAME: LATEST_VERSION is empty"
	exit 0
fi

########################################################################################################################

INSTALL_TO='/Applications/MakeMKV.app'

INSTALLED_VERSION=`defaults read ${INSTALL_TO}/Contents/Info CFBundleShortVersionString | tr -dc '[0-9].'`

autoload is-at-least

is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

if [ "$?" = "0" ]
then
	echo "$NAME: Up-To-Date (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"
	exit 0
fi

########################################################################################################################

echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"

FILENAME="$HOME/Downloads/MakeMKV-${LATEST_VERSION}.dmg"

########################################################################################################################

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

########################################################################################################################

	# This will accept the DMG's EULA without reading it, just like you would have!
MNTPNT=`echo -n "Y" \
	| hdid -plist "$FILENAME" 2>/dev/null \
	| fgrep '/Volumes/' \
	| sed 's#</string>##g ; s#.*<string>##g'`

if [[ "$MNTPNT" == "" ]]
then
	echo "$NAME: MNTPNT is empty"
	exit 1
fi

if [ -e "$INSTALL_TO" ]
then
		# move installed version to trash 
	mv -vf "$INSTALL_TO" "$HOME/.Trash/MakeMKV.$INSTALLED_VERSION.app"
fi

ditto -v "$MNTPNT/MakeMKV.app" "$INSTALL_TO"

diskutil eject "$MNTPNT"

exit 0
#EOF
