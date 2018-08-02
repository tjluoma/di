#!/bin/zsh -f
# Purpose: Download and install Screens version 4
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-07-16

NAME="$0:t:r"

INSTALL_TO='/Applications/Screens 4.app'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

XML_FEED="https://updates.devmate.com/com.edovia.screens4.mac.xml"

# @TODO - sparkle:version also exists in feed, and is probably worth checking too, although both seem to be incremented when an update occurs

INFO=($(curl -sfL "$XML_FEED" \
		| tr ' ' '\012' \
		| egrep '^(url|sparkle:shortVersionString)=' \
		| head -2 \
		| awk -F'"' '//{print $2}'))

URL="$INFO[1]"

LATEST_VERSION="$INFO[2]"

if [ "$URL" = "" -o "$LATEST_VERSION" = "" ]
then
	echo "$NAME: Cannot continue. Either URL ($URL) or LATEST_VERSION ($LATEST_VERSION) is empty."
	echo "$NAME: Check \"$XML_FEED\" for format changes. This is what I got for \"$INFO\": "
	echo "$INFO"
	exit 1
fi

if [[ -d "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=$(defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString)

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

	if [[ ! -w "$INSTALL_TO" ]]
	then
		echo "$NAME: Cannot install because \"$INSTALL_TO\" exists, but is not writable."
		exit 1
	fi
fi

	####################################################################################
	####################################################################################
	##
	## Hard-coding 'Screens' into $FILENAME because otherwise we end up with filenames like:
	## 		~/Downloads/Screens 4-4.5.7.zip
	## instead of
	## 		~/Downloads/Screens-4.5.7.zip
	## which is clearly superior.
	##
FILENAME="$HOME/Downloads/Screens-${LATEST_VERSION}.zip"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

if [ -e "$INSTALL_TO" ]
then
	mv -f "$INSTALL_TO" "$HOME/.Trash/$INSTALL:t:r.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

	# Extract from the .zip file and install (this will leave the .zip file in place)
ditto --noqtn -xk "$FILENAME" "$INSTALL_TO:h/"

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: Installation of $INSTALL_TO was successful."

	[[ "$LAUNCH" == "yes" ]] && open -a "$INSTALL_TO"

else
	echo "$NAME: Installation of \"$INSTALL_TO\" failed (\$EXIT = $EXIT)\nThe downloaded file can be found at $FILENAME."
	exit 1
fi

exit 0

#EOF
