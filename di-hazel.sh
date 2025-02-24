#!/usr/bin/env zsh -f
# Purpose: 	Download and install Hazel 6
#
# From:		Timothy J. Luoma
# Mail:		luomat at gmail dot com
# Date:		2025-02-13
# Verified:	2025-02-24

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

autoload is-at-least

INSTALL_TO='/Applications/Hazel.app'

STATIC_DOWNLOAD_URL='https://www.noodlesoft.com/Products/Hazel/download'

	# find the actual URL from the STATIC_DOWNLOAD_URL
URL=$(curl --head -sfLS "$STATIC_DOWNLOAD_URL" \
		| egrep '^Location: ' \
		| awk '{print $2}' \
		| tr -d '\r')

	# This feed doesn't have the URL to the latest version in it, just the version number
	# AKA
	# https://www.noodlesoft.com/Products/Hazel/generate-appcast.php
XML_FEED='https://www.noodlesoft.com/Products/Hazel/appcast.php'

LATEST_VERSION=$(curl -sfLS "$XML_FEED" \
	| fgrep '<sparkle:version>' \
	| head -1 \
	| sed 's#.*<sparkle:version>##g ; s#</sparkle:version>##g')

RELEASE_NOTES_URL='https://www.noodlesoft.com/Products/Hazel/changelog.php'

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleShortVersionString)

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	VERSION_COMPARE="$?"

	if [ "$VERSION_COMPARE" = "0" ]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION)"
		exit 0
	fi

	echo "$NAME: Outdated: $INSTALLED_VERSION vs $LATEST_VERSION"

	FIRST_INSTALL='no'

	if [[ ! -w "$INSTALL_TO" ]]
	then
		echo "$NAME: '$INSTALL_TO' exists, but you do not have 'write' access to it, therefore you cannot update it." >>/dev/stderr

		exit 2
	fi

else

	FIRST_INSTALL='yes'

fi

FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${${LATEST_VERSION}// /}.dmg"

RELEASE_NOTES_TXT="$FILENAME:r.txt"

if [[ -e "$RELEASE_NOTES_TXT" ]]
then

	cat "$RELEASE_NOTES_TXT"

else

	if (( $+commands[lynx] ))
	then

		RELEASE_NOTES=$(curl -sfLS "$RELEASE_NOTES_URL" | lynx -assume_charset=UTF-8 -stdin -pseudo_inlines -dump -nomargins -width=10000)

		echo "${RELEASE_NOTES}\n\nSource:\t${RELEASE_NOTES_URL}\n\nVersion: ${LATEST_VERSION}\nURL: $URL" | tee "$RELEASE_NOTES_TXT"

	fi

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

	# if there is already a local sha256 don't add another one
egrep -q '^Local sha256:$' "$FILENAME:r.txt" 2>/dev/null

EXIT="$?"

if [ "$EXIT" = "1" -o ! -e "$FILENAME:r.txt" ]
then
	(cd "$FILENAME:h" ; \
		echo "\n\nLocal sha256:" ; \
		shasum -a 256 "$FILENAME:t" \
	)  >>| "$FILENAME:r.txt"
fi

echo "$NAME: Accepting license and Mounting $FILENAME:"

MNTPNT=$(echo -n "Y" | hdid -plist "$FILENAME" 2>/dev/null | fgrep '/Volumes/' | sed 's#</string>##g ; s#.*<string>##g')

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

	# If I use the 'ditto' process below, macOS relentlessly claims that Hazel is damaged and
	# cannot be opened, and should be moved to the trash. I assume this has something to do
	# with Gatekeeper etc. If we open the app from the mounted DMG, the user can install
	# it themselves. But this is less than ideal, especially for updates, because it
	# requires human intervention. However, until I can figure out an alternative, this is the
	# best we can do. And by 'we' I mean 'me'.
open "$MNTPNT/Hazel.app"


###################################################################################################
#
#
# echo "$NAME: Installing '$MNTPNT/$INSTALL_TO:t' to '$INSTALL_TO': "
#
# ditto --noqtn -v "$MNTPNT/$INSTALL_TO:t" "$INSTALL_TO"
#
# EXIT="$?"
#
# if [[ "$EXIT" == "0" ]]
# then
# 	echo "$NAME: Successfully installed $INSTALL_TO"
# else
# 	echo "$NAME: ditto failed"
#
# 	exit 1
# fi
#
# [[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"
#
# echo -n "$NAME: Unmounting $MNTPNT: " && diskutil eject "$MNTPNT"
#
###################################################################################################

exit 0
# EOF