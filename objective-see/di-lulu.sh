#!/usr/bin/env zsh -f
# Purpose: Download and install/update the latest version of "LuLu"
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-09-13

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

HOMEPAGE="https://objective-see.com/products/lulu.html"

DOWNLOAD_PAGE="https://objective-see.com/products/lulu.html"

RELEASE_NOTES_URL='https://objective-see.com/products/changelogs/LuLu.txt'

SUMMARY="In today's connected world, it is rare to find an application or piece of malware that doesn't talk to a remote server. Let's control this! LuLu is the free, shared-source macOS firewall that aims to block unknown outgoing connections, unless explicitly approved by the user."

INSTALL_TO='/Applications/Lulu.app'

INFO=$(curl -H "Accept-Encoding: gzip,deflate" -sfLS "$HOMEPAGE" | gunzip -f -c)

URL=$(echo "$INFO" | tr '"' '\012' | egrep 'http.*\.dmg$' | head -1)

EXPECTED_SHA1=$(echo "$INFO" | fgrep 'SHA-1' | sed -e 's#</span>##g' | awk '{print $NF}')

LATEST_VERSION=$(echo "$URL:t:r" | tr -dc '[0-9]\.')

# If any of these are blank, we cannot continue
if [ "$URL" = "" -o "$LATEST_VERSION" = "" -o "$EXPECTED_SHA1" = "" ]
then
	echo "$NAME: Error: bad data received:
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	EXPECTED_SHA1: $EXPECTED_SHA1
	"

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

SHA_FILE="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${LATEST_VERSION}.sha1.txt"

echo "$EXPECTED_SHA1  $FILENAME:t" >| "$SHA_FILE"

( curl -H "Accept-Encoding: gzip,deflate" -sfLS "$RELEASE_NOTES_URL" \
	| gunzip -f -c) | tee "$FILENAME:r.txt"

OS_VER=$(SYSTEM_VERSION_COMPAT=1 sw_vers -productVersion | cut -d. -f2)

if [ "$OS_VER" -lt "15" ]
then
	echo "$NAME: [WARNING] '$INSTALL_TO:t' is only compatible with macOS versions 10.15 and higher (you are using 10.$OS_VER)."
	echo "$NAME: [WARNING] Will download, but the app might not install or function properly."
fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

##

echo "$NAME: Checking '$FILENAME' against '$SHA_FILE':"

cd "$FILENAME:h"

shasum -c "$SHA_FILE"

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: SHA-1 verification passed"

else
	echo "$NAME: SHA-1 verification failed (\$EXIT = $EXIT)"

	exit 1
fi

##

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
	echo "$NAME: moving old installed version to '$HOME/.Trash'..."
	mv -f "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.${INSTALLED_VERSION}_${INSTALLED_BUILD}.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then

		echo "$NAME: failed to move '$INSTALL_TO' to '$HOME/.Trash'. ('mv' \$EXIT = $EXIT)"

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

