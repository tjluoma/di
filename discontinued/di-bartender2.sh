#!/bin/zsh -f
# Purpose: Download and install the latest version of Bartender 2 (note that v3 is also available.)
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-04-16, updated and verified 2018-08-06

NAME="$0:t:r"

INSTALL_TO="/Applications/Bartender 2.app"

XML_FEED='https://www.macbartender.com/B2/updates/updates.php'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

LAUNCH='no'

	# This will work even if there is a space in the enclosure URL
	# We have to limit to 'https://macbartender.com/B2/updates/2'
	# because the feed includes version 3 items too.

IFS=$'\n' INFO=($(curl -sfL "$XML_FEED" \
				| fgrep 'https://macbartender.com/B2/updates/2' \
				| egrep 'sparkle:version|sparkle:shortVersionString=|url=' \
				| tail -1 \
				| sort ))

URL=$(echo "$INFO" | sed 's#.*https://#https://#g; s#.zip".*#.zip#g;')

LATEST_VERSION=$(echo "$INFO" | sed 's#.*sparkle:shortVersionString="##g; s#".*##g; ')

LATEST_BUILD=$(echo "$INFO" | sed 's#.*sparkle:version="##g; s#".*##g;')

FILENAME="$HOME/Downloads/Bartender-${LATEST_VERSION}_${LATEST_BUILD}.zip"

	# If any of these are blank, we should not continue
if [ "$INFO" = "" -o "$LATEST_BUILD" = "" -o "$URL" = "" -o "$LATEST_VERSION" = "" ]
then
	echo "$NAME: Error: bad data received:
	LATEST_VERSION: $LATEST_VERSION
	LATEST_BUILD: $LATEST_BUILD
	URL: $URL
	FILENAME: $FILENAME
	"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleShortVersionString)

	INSTALLED_BUILD=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleVersion)

	autoload is-at-least

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	VERSION_COMPARE="$?"

	is-at-least "$LATEST_BUILD" "$INSTALLED_BUILD"

	BUILD_COMPARE="$?"

	if [ "$VERSION_COMPARE" = "0" -a "$BUILD_COMPARE" = "0" ]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION/$INSTALLED_BUILD)"
		exit 0
	fi

	echo "$NAME: Outdated: $INSTALLED_VERSION/$INSTALLED_BUILD vs $LATEST_VERSION/$LATEST_BUILD"

	FIRST_INSTALL='no'

else

	FIRST_INSTALL='yes'
fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

UNZIP_TO=$(mktemp -d "${TMPDIR-/tmp/}${NAME}-XXXXXXXX")

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
	echo "$NAME: Moving existing (old) \"$INSTALL_TO\" to \"$HOME/.Trash/\"."

	pgrep -xq "$INSTALL_TO:t:r" && LAUNCH='yes' && osascript -e 'tell application "$INSTALL_TO:t:r" to quit'

	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then

		echo "$NAME: failed to move existing $INSTALL_TO to $HOME/.Trash/"

		exit 1
	fi
fi

echo "$NAME: Moving new version of '$INSTALL_TO:t' (from '$UNZIP_TO') to '$INSTALL_TO'."

	# Move the file out of the folder
mv -vn "$UNZIP_TO/Bartender 2.app" "$INSTALL_TO"

EXIT="$?"

if [[ "$EXIT" = "0" ]]
then

	echo "$NAME: Successfully installed '$UNZIP_TO/$INSTALL_TO:t' to '$INSTALL_TO'."

else
	echo "$NAME: Failed to move '$UNZIP_TO/$INSTALL_TO:t' to '$INSTALL_TO'."

	exit 1
fi

if [ "$LAUNCH" = "yes" ]
then
	echo "$NAME: Launching $INSTALL_TO:t:r"
	open -a "$INSTALL_TO:t:r"
fi

exit 0
#
#EOF

