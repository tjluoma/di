#!/usr/bin/env zsh -f
# Purpose: Download and install the latest version of Kindle for Mac
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2015-10-12

NAME="$0:t:r"

	# This is where the app will be installed or updated.
if [[ -d '/Volumes/Applications' ]]
then
	INSTALL_TO='/Volumes/Applications/Kindle.app'
else
	INSTALL_TO='/Applications/Kindle.app'
fi

HOMEPAGE="https://www.amazon.com/kindle-dbs/fd/kcp"

DOWNLOAD_PAGE="https://www.amazon.com/kindlemacdownload"

SUMMARY="Read Kindle books on your Mac."

# No RELEASE_NOTES_URL available

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

function die
{
	echo "$NAME: $@"
	exit 1
}

if [ -d "$INSTALL_TO" -a ! -w "$INSTALL_TO" ]
then
	echo "$NAME: Although $INSTALL_TO exists, it is not writable."
	exit 0
fi

	# NOTE: We do not want to use 'curl --location' here because that will not give us the information we need
	# We _want_ to get the basic HTML redirection page, because that has the actual, current URL in it
	#
	# <!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
	# <html><head>
	# <title>301 Moved Permanently</title>
	# </head><body>
	# <h1>Moved Permanently</h1>
	# <p>The document has moved <a href="https://s3.amazonaws.com/kindleformac/50131/KindleForMac-50131.dmg">here</a>.</p>
	# </body></html>
	#
	# The 'awk' command will give us an URL such as
	# 	https://s3.amazonaws.com/kindleformac/50131/KindleForMac-50131.dmg
URL=$(curl --silent 'https://www.amazon.com/kindlemacdownload' | awk -F'"' '/https/{print $2}')

[[ "$URL" == "" ]] && die "URL is empty."

LATEST_VERSION=`echo "$URL:t:r" | tr -dc '[0-9]'`

[[ "$LATEST_VERSION" == "" ]] && die "LATEST_VERSION is empty."

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleVersion)

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

	if [[ -e "$INSTALL_TO/Contents/_MASReceipt/receipt" ]]
	then
		echo "$NAME: $INSTALL_TO was installed from the Mac App Store and cannot be updated by this script."
		echo "	See <https://apps.apple.com/us/app/kindle/id405399194?mt=12> or"
		echo "	<macappstore://apps.apple.com/us/app/kindle/id405399194>"
		echo "	Please use the App Store app to update it: <macappstore://showUpdatesPage?scan=true>"
		exit 0
	fi

else

	FIRST_INSTALL='yes'
fi

	# Should be something like KindleForMac-50131.dmg
FILENAME="$HOME/Downloads/$URL:t"

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && die "Download of $URL failed (EXIT = $EXIT)"

[[ ! -e "$FILENAME" ]] && die "$FILENAME does not exist."

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 1

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


	# Rename the generic filename to include the Version and Build information
INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleShortVersionString)

  INSTALLED_BUILD=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleVersion)

mv -vf "$FILENAME" "$FILENAME:h/$INSTALL_TO:t:r-${INSTALLED_VERSION}_${INSTALLED_BUILD}.dmg"

exit 0
#
#EOF
