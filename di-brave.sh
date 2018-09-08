#!/bin/zsh -f
# Purpose: Download and install the latest version of Brave from: <https://brave.com>
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-08-04

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

HOMEPAGE="https://brave.com"

DOWNLOAD_PAGE="https://brave.com/download/"

SUMMARY="Much more than a browser, Brave is a new way of thinking about how the web works."

	# if you want to install beta releases
	# create a file (empty, if you like) using this file name/path:
PREFERS_BETAS_FILE="$HOME/.config/di/brave-prefer-betas.txt"

if [[ -e "$PREFERS_BETAS_FILE" ]]
then
	NAME="$NAME (beta releases)"

	INSTALL_TO='/Applications/Brave-Beta.app'

	URL_PREVIEW=`curl -sfL "https://github.com/brave/browser-laptop/releases.atom" \
	| fgrep '/browser-laptop/releases/tag/' \
	| fgrep -i 'beta' \
	| head -1 \
	| sed 's#.*https#https#g; s#"/>##g'`

	URL=`curl -sfL "$URL_PREVIEW" \
	| egrep '/brave/browser-laptop/releases/.*\.dmg"' \
	| fgrep -i 'beta' \
	| sed 's#.dmg.*#.dmg#g ; s#.*/brave/#https://github.com/brave/#g'`

else
	# This is for non-beta

	INSTALL_TO='/Applications/Brave.app'

	URL_PREVIEW=`curl -sfL "https://github.com/brave/browser-laptop/releases.atom" \
	| fgrep '/browser-laptop/releases/tag/' \
	| fgrep -vi 'beta' \
	| head -1 \
	| sed 's#.*https#https#g; s#"/>##g'`

	URL=`curl -sfL "$URL_PREVIEW" \
	| egrep '/brave/browser-laptop/releases/.*\.dmg"' \
	| fgrep -vi 'beta' \
	| sed 's#.dmg.*#.dmg#g ; s#.*/brave/#https://github.com/brave/#g'`

fi

LATEST_VERSION=`echo "$URL:t:r" | tr -dc '[0-9]\.'`

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

FILENAME="$HOME/Downloads/$URL:t"

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

[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"

echo -n "$NAME: Unmounting $MNTPNT: " && diskutil eject "$MNTPNT"

exit 0
#EOF
