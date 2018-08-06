#!/bin/zsh -f
# Purpose: Download and install new version of Calibre
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2014-07-25

NAME="$0:t:r"

INSTALL_TO='/Applications/calibre.app'

zmodload zsh/stat

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

CURRENT_VERSION=`curl -sfL 'http://status.calibre-ebook.com/latest'`

	# curent version is empty, something went wrong
[[ "$CURRENT_VERSION" = "" ]] && exit 0

##

if [ -e '/Applications/calibre.app/Contents/Info.plist' ]
then
	LOCAL_VERSION=`defaults read '/Applications/calibre.app/Contents/Info.plist' CFBundleShortVersionString `
else
	LOCAL_VERSION='0'
fi

	# no update needed
[[ "$CURRENT_VERSION" = "$LOCAL_VERSION" ]] && echo "$NAME: calibre $CURRENT_VERSION is current" && exit 0

##

URL="http://download.calibre-ebook.com/${CURRENT_VERSION}/calibre-${CURRENT_VERSION}.dmg"

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${CURRENT_VERSION}.dmg"

########################################################################################################################

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
#		Installation
#

echo "NAME: Mounting $FILENAME:"

MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
 		| fgrep -A 1 '<key>mount-point</key>' \
 		| tail -1 \
 		| sed 's#</string>.*##g ; s#.*<string>##g')


if [ "$MNTPNT" = "" ]
then
	echo "$NAME: Failed to mount $FILENAME"
	exit 1
fi


if [ -e "$INSTALL_TO" ]
then
	mv -vn "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$LOCAL_VERSION.app"
fi

if [ -e "$INSTALL_TO" ]
then
	echo "$NAME: Failed to remove existing $INSTALL_TO"
	exit 1
fi


echo "$NAME: Installing '$MNTPNT/$INSTALL_TO:t' to '$INSTALL_TO': "

ditto --noqtn -v "$MNTPNT/$INSTALL_TO:t" "$INSTALL_TO"

EXIT="$?"

if [[ "$EXIT" != "0" ]]
then
	echo "$NAME: ditto failed"

	exit 1
fi

echo "$NAME: Installation success. Unmounting $MNTPNT:"

	# Try to eject the DMG
diskutil eject "$MNTPNT"

exit
#
#EOF
