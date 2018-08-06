#!/bin/zsh -f
# Purpose: Download and install the latest version of TextExpander 5 (note: TE6 is a subscription app)
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-04

NAME="$0:t:r"

INSTALL_TO='/Applications/TextExpander 5.app'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

	##  2018-07-17 - this is the feed that I was using
	# http://updates.smilesoftware.com/com.smileonmymac.textexpander.xml
	# Don't use 'https://smilesoftware.com/appcast/update.php'

XML_FEED='https://updates.devmate.com/com.smileonmymac.textexpander.xml'

# sparkle:version exists in feed, but TextExpander 5 is EOL and the numbers always seem to be in unison, so probably not worth adding

INFO=($(curl -sfL "$XML_FEED" \
	| tr -s ' ' '\012' \
	| egrep '(url|sparkle:shortVersionString)=' \
	| head -2 \
	| awk -F'"' '//{print $2}'))

URL="$INFO[1]"

LATEST_VERSION="$INFO[2]"

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

autoload is-at-least

is-at-least 5.1.5 ${LATEST_VERSION}

EXIT="$?"

if [[ "$EXIT" == "1" ]]
then
		# echo "$NAME: Faking version 5.1.5 data because it doesn't exist in the regular XML_FEED."
	LATEST_VERSION='5.1.5'
	URL='https://cdn.textexpander.com/mac/TextExpander_5.1.5.zip'
fi

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo '0'`

	if [[ "$LATEST_VERSION" == "$INSTALLED_VERSION" ]]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION)"
		exit 0
	fi

	autoload is-at-least

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	if [ "$?" = "0" ]
	then
		echo "$NAME: Installed version ($INSTALLED_VERSION) is ahead of official version $LATEST_VERSION"
		exit 0
	fi

	echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"

fi

FILENAME="$HOME/Downloads/TextExpander-$LATEST_VERSION.zip"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

if [[ -e "$INSTALL_TO" ]]
then
		# Quit app, if running
	pgrep -xq "TextExpander" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "TextExpander" to quit'

	pgrep -xq "TextExpander Helper" \
	&& osascript -e 'tell application "TextExpander Helper" to quit'

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/TextExpander.$INSTALLED_VERSION.app"
fi


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
	# Note that we are renaming "TextExpander.app" to "TextExpander 5.app" at the same time
mv -vn "$UNZIP_TO/TextExpander.app" "$INSTALL_TO"

EXIT="$?"

if [[ "$EXIT" = "0" ]]
then

	echo "$NAME: Successfully installed '$UNZIP_TO/$INSTALL_TO:t' to '$INSTALL_TO'."

else
	echo "$NAME: Failed to move '$UNZIP_TO/$INSTALL_TO:t' to '$INSTALL_TO'."

	exit 1
fi





	# We need to launch this or else TextExpander's snippets won't expand
open --background "$INSTALL_TO/Contents/Helpers/TextExpander Helper.app"

[[ "$LAUNCH" == "yes" ]] && open --background "$INSTALL_TO"


exit 0
#EOF
