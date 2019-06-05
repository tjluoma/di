#!/bin/zsh -f
# Purpose: Download and install the latest version of BetterTouchTool
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2016-01-19

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

NAME="$0:t:r"

HOMEPAGE="https://folivora.ai"

DOWNLOAD_PAGE="https://bettertouchtool.net/releases/BetterTouchTool.zip"

SUMMARY="BetterTouchTool is a great, feature packed app that allows you to customize various input devices on your Mac."

INSTALL_TO="/Applications/BetterTouchTool.app"

RELEASE_NOTES_URL="https://updates.bettertouchtool.net/bettertouchtool_release_notes.html"

## 2019-05-23 - https://updates.bettertouchtool.net/appcast.xml

# URL=$(curl -sfL "$RELEASE_NOTES_URL" \
# 	| awk -F'"' '/http.*\.zip/{print $2}' \
# 	| head -1)

FILENAME=$(curl -sfL 'https://bettertouchtool.net/releases/' | fgrep -i .zip | head -1 | sed 's#</a>.*##g ; s#.*>##g')

URL="https://bettertouchtool.net/releases/$FILENAME"

LATEST_VERSION=`echo "$FILENAME:t:r" | tr -dc '[0-9]\.'`

	# If any of these are blank, we should not continue
if [ "$LATEST_VERSION" = "" -o "$URL" = "" ]
then
	echo "$NAME: Error: bad data received:\nLATEST_VERSION: ${LATEST_VERSION}\nURL: ${URL}"
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

HEADER=$(curl -sfL "$RELEASE_NOTES_URL" | fgrep "$URL")

BODY=$(curl -sfL "$RELEASE_NOTES_URL" \
| sed '1,/<b>BetterTouchTool <a href="http:\/\/bettertouchtool.net\/releases\//d; /<b>BetterTouchTool <a href="http:\/\/bettertouchtool.net\/releases\//,$d')

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}.zip"

if (( $+commands[lynx] ))
then

	(  echo "$NAME: Release Notes for $HEADER\n$BODY" \
		| lynx -dump -nomargins -width=1000 -assume_charset=UTF-8 -pseudo_inlines -stdin ;
		echo "\nSource: <$RELEASE_NOTES_URL>" ) | tee "$FILENAME:r.txt"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

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

	pgrep -xq "$INSTALL_TO:t:r" \
	&& LAUNCH='yes' \
	&& osascript -e "tell application \"$INSTALL_TO:t:r\" to quit"

	echo "$NAME: Moving existing (old) '$INSTALL_TO' to '$HOME/.Trash/'."

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
EOF


##
## 2018-08-04 - this feed is outdated.
## https://updates.bettertouchtool.net/bettertouchtool_release_notes.html is
## not an RSS/Sparkle feed, but it's the best place to check for updates.
##
# XML_FEED="https://updates.bettertouchtool.net/appcast.xml"
#
# url="https://bettertouchtool.net/releases/btt2.427_recovery4.zip"
# sparkle:version="787"
# sparkle:shortVersionString="2.427"

