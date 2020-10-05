#!/usr/bin/env zsh -f
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

autoload is-at-least

NAME="$0:t:r"

HOMEPAGE="https://folivora.ai"

DOWNLOAD_PAGE="https://bettertouchtool.net/releases/BetterTouchTool.zip"

SUMMARY="BetterTouchTool is a great, feature packed app that allows you to customize various input devices on your Mac."

INSTALL_TO="/Applications/BetterTouchTool.app"

RELEASE_NOTES_URL="https://updates.bettertouchtool.net/bettertouchtool_release_notes.html"

FILENAME=$(curl -sfL 'https://bettertouchtool.net/releases/' | fgrep -i .zip | head -1 | sed 's#</a>.*##g ; s#.*>##g')

URL="https://bettertouchtool.net/releases/$FILENAME"

VERSION_INFO=($(echo "$FILENAME:t:r" | sed 's#btt##g ; s#-# #g'))

LATEST_VERSION="$VERSION_INFO[1]"

LATEST_BUILD="$VERSION_INFO[2]"


	# If any of these are blank, we should not continue
if [ "$LATEST_VERSION" = "" -o "$LATEST_BUILD" = "" -o "$FILENAME" = "" ]
then
	echo "$NAME: Error: bad data received:\nLATEST_VERSION: ${LATEST_VERSION}\nLATEST_BUILD: ${LATEST_BUILD}\nFILENAME: ${FILENAME}"
	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleShortVersionString)

	INSTALLED_BUILD=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleVersion)

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

	if [[ ! -w "$INSTALL_TO" ]]
	then
		echo "$NAME: '$INSTALL_TO' exists, but you do not have 'write' access to it, therefore you cannot update it." >>/dev/stderr

		exit 2
	fi

else

	FIRST_INSTALL='yes'
fi

FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${${LATEST_VERSION}// /}_${${LATEST_BUILD}// /}.zip"

if (( $+commands[lynx] ))
then

	curl -sfLS "$RELEASE_NOTES_URL" >| "$FILENAME:r.html"

	( awk '/<b>/{i++}i==1' "$FILENAME:r.html" \
		| lynx -dump -nomargins -width=1000 -assume_charset=UTF-8 -pseudo_inlines -stdin ;
		echo "\nURL: ${URL}\nSource: <$RELEASE_NOTES_URL>" ) | tee "$FILENAME:r.txt"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

####################################################################################

egrep -q '^Local sha256:$' "$FILENAME:r.txt" 2>/dev/null

EXIT="$?"

if [ "$EXIT" = "1" -o ! -e "$FILENAME:r.txt" ]
then
	(cd "$FILENAME:h" ; \
	echo "\n\nLocal sha256:" ; \
	shasum -a 256 "$FILENAME:t" \
	)  >>| "$FILENAME:r.txt"
fi


####################################################################################

(command unzip -l "$FILENAME" 2>&1 )>/dev/null

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: '$FILENAME' is a valid zip file."

else
	echo "$NAME: '$FILENAME' is an invalid zip file (\$EXIT = $EXIT)"

	mv -fv "$FILENAME" "$HOME/.Trash/"

	mv -fv "$FILENAME:r".* "$HOME/.Trash/"

	exit 0

fi

####################################################################################

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

