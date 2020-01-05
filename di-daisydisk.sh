#!/usr/bin/env zsh -f
# Purpose: Download and install latest version of DaisyDisk from http://daisydiskapp.com
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-24

	# This is where the app will be installed or updated.
if [[ -d '/Volumes/Applications' ]]
then
	INSTALL_TO='/Volumes/Applications/DaisyDisk.app'
	TRASH="/Volumes/Applications/.Trashes/$UID"
else
	INSTALL_TO='/Applications/DaisyDisk.app'
	TRASH="/.Trashes/$UID"
fi

[[ ! -w "$TRASH" ]] && TRASH="$HOME/.Trash"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

NAME="$0:t:r"

HOMEPAGE="https://daisydiskapp.com"

DOWNLOAD_PAGE="https://daisydiskapp.com/downloads/DaisyDisk.zip"

SUMMARY="DaisyDisk also gives you a great overview of all connected disks, be it Macintosh HD, Thunderbolt disk, flash, network storage, you name it."

OS_VER=`sw_vers -productVersion`

	# If we don't tell it we are using at least version 4, we get an empty feed
MAJOR_VERSION='4'

XML_FEED="http://www.daisydiskapp.com/downloads/appcastFeed.php?osVersion=${OS_VER}&appVersion=${MAJOR_VERSION}&appEdition=Standard"

RELEASE_NOTES_URL=$(curl -sfL "$XML_FEED" \
	| fgrep '<sparkle:releaseNotesLink>' \
	| head -1 \
	| sed 's#.*<sparkle:releaseNotesLink>##g ; s#</sparkle:releaseNotesLink>##g ; s#\&amp;#\&#g')

INFO=($(curl -sfL "$XML_FEED" \
		| tr -s ' ' '\012' \
		| egrep 'sparkle:version=|url=' \
		| head -2 \
		| sort \
		| awk -F'"' '/^/{print $2}'))

	# "Sparkle" will always come before "url" because of "sort"
LATEST_VERSION="$INFO[1]"
# URL="$INFO[2]"

URL='https://daisydiskapp.com/downloads/DaisyDisk.zip'

	# If any of these are blank, we should not continue
if [ "$INFO" = "" -o "$LATEST_VERSION" = "" -o "$URL" = "" ]
then
	echo "$NAME: Error: bad data received:
	INFO: $INFO
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	autoload is-at-least

	INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo '4'`

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	if [ "$?" = "0" ]
	then
		echo "$NAME: Up-To-Date ($LATEST_VERSION)"
		exit 0
	fi

	echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"

	if [[ -e "$INSTALL_TO/Contents/_MASReceipt/receipt" ]]
	then
		echo "$NAME: $INSTALL_TO was installed from the Mac App Store and cannot be updated by this script."
		echo "	See <https://apps.apple.com/us/app/daisydisk/id411643860?mt=12> or"
		echo "	<macappstore://apps.apple.com/us/app/daisydisk/id411643860>"
		echo "	Please use the App Store app to update it: <macappstore://showUpdatesPage?scan=true>"
		exit 0
	fi

fi

FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${LATEST_VERSION}.zip"

if (( $+commands[lynx] ))
then

	( echo "$NAME: Release Notes for $INSTALL_TO:t:r:" ;
		curl -sfL "$RELEASE_NOTES_URL" \
		| sed "1,/<div class='version'>/d; /<div class='version'>/,\$d" \
		| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin \
		| tr -s '\t| ' ' ' \
		| sed '/./,/^$/!d' ;
		echo "\nSource: <$RELEASE_NOTES_URL>" ) \
	| tee "$FILENAME:r.txt"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

(cd "$FILENAME:h" ; echo "\nLocal sha256:" ; shasum -a 256 -p "$FILENAME:t" ) >>| "$FILENAME:r.txt"

	## make sure that the .zip is valid before we proceed
(command unzip -l "$FILENAME" 2>&1 )>/dev/null

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: '$FILENAME' is a valid zip file."

else
	echo "$NAME: '$FILENAME' is an invalid zip file (\$EXIT = $EXIT)"

	mv -fv "$FILENAME" "$TRASH/"

	mv -fv "$FILENAME:r".* "$TRASH/"

	exit 0

fi

	## unzip to a temporary directory
UNZIP_TO=$(mktemp -d "${TRASH}/${NAME}-XXXXXXXX")

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

	echo "$NAME: Moving existing (old) '$INSTALL_TO' to '$TRASH/'."

	mv -vf "$INSTALL_TO" "$TRASH/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then

		echo "$NAME: failed to move existing '$INSTALL_TO' to '$TRASH'."

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
