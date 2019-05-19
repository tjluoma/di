#!/bin/zsh -f
# Purpose: Download and install Mailplane.app v3 or 4, depending on which is installed (if any)
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2018-08-20

## 2018-11-05 - the format of the XML_FEED seems to have changed

NAME="$0:t:r"

HOMEPAGE="https://mailplaneapp.com"

DOWNLOAD_PAGE="https://update.mailplaneapp.com/mailplane_4.php"

SUMMARY="The best way to use Gmail on your Mac."

# no RELEASE_NOTES_URL found

INSTALL_TO="/Applications/Mailplane.app"

OS_VER=$(sw_vers -productVersion)

INSTALLED_VERSION=$(defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo '4.0.0')

INSTALLED_BUILD=$(defaults read "$INSTALL_TO/Contents/Info" CFBundleVersion 2>/dev/null || echo '4000')

XML_FEED="https://update.mailplaneapp.com/appcast.php?osVersion=${OS_VER}&appVersion=${INSTALLED_BUILD}&shortVersionString=${INSTALLED_VERSION}&selectedLanguage=en-US"

INFO=($(curl -sfL "$XML_FEED" \
		| tr -s ' ' '\012' \
		| egrep 'sparkle:shortVersionString=|sparkle:version=|url=' \
		| head -3 \
		| sort \
		| awk -F'"' '/^/{print $2}' ))

	# "Sparkle" will always come before "url" because of "sort"
LATEST_VERSION="$INFO[1]"
LATEST_BUILD="$INFO[2]"
URL="$INFO[3]"

	# n.b. 'http://update.mailplaneapp.com/mailplane_4.php' does redirect to the latest v4 version
	# (after a few redirects along the way). Here's the current version
	# Location: https://update.mailplaneapp.com/builds/Mailplane_4_4516.tbz

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

FILENAME="$HOME/Downloads/MailPlane-4-${LATEST_VERSION}_${LATEST_BUILD}.tbz"

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

UNZIP_TO=$(mktemp -d "${TMPDIR-/tmp/}${NAME}-XXXXXXXX")

echo "$NAME: Unzipping $FILENAME to $UNZIP_TO"

tar -x -C "$UNZIP_TO" -j -f "$FILENAME"

EXIT="$?"

if [[ "$EXIT" != "0" ]]
then
	echo "$NAME: 'tar' failed (\$EXIT = $EXIT)\nThe downloaded file can be found at $FILENAME."
	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then
		# Quit app, if running
	pgrep -xq "$INSTALL_TO:t:r" \
	&& LAUNCH='yes' \
	&& osascript -e "tell application \"$INSTALL_TO:t:r\" to quit"

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/MailPlane.$INSTALLED_VERSION.$INSTALLED_BUILD.app"
fi

mv -vf "$UNZIP_TO/$INSTALL_TO:t" "$INSTALL_TO"

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: Installation of $INSTALL_TO was successful"
	exit 0
else
	echo "$NAME: 'mv' failed (\$EXIT = $EXIT)"

	exit 1
fi

exit 0
#
#EOF
