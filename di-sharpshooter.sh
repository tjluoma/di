#!/usr/bin/env zsh -f
# Purpose: 	Download and install the latest version of Sharpshooter
#
# From:		Timothy J. Luoma
# Mail:		luomat at gmail dot com
# Date:		2018-07-10
# Verified:	2025-02-23 [no longer sold or supported, but still downloads]

NAME="$0:t:r"

INSTALL_TO='/Applications/Sharpshooter.app'

HOMEPAGE="http://www.kerlmax.com/products/sharpshooter/"

DOWNLOAD_PAGE="http://www.kerlmax.com/products/sharpshooter/"

SUMMARY="Sharpshooter lets you manipulate and process the screenshot while it is still fresh on your mind."

XML_FEED='http://www.kerlmax.com/products/sharpshooter/sharpshooter_v2_appcast.php'

RELEASE_NOTES_URL=$(curl -sfL "$XML_FEED" \
	| fgrep '<sparkle:releaseNotesLink>' \
	| head -1 \
	| sed 's#.*<sparkle:releaseNotesLink>##g ; s#</sparkle:releaseNotesLink>##g')


if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

LAUNCH='no'

# sparkle:shortVersionString and sparkle:version are identical, so no need to check both

	# This will work even if there is a space in the enclosure URL
IFS=$'\n' INFO=($(curl -sfL "$XML_FEED" \
	| egrep 'sparkle:shortVersionString=|url=' \
	| head -2 \
	| sed 's#.*url="##g; s#"$##g; s#.*sparkle:shortVersionString="##g'))

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

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-$LATEST_VERSION.zip"

if (( $+commands[lynx] ))
then

	( echo -n "$NAME: Release Notes for $INSTALL_TO:t:r Version "
		curl -sfL "${RELEASE_NOTES_URL}" \
		| sed '1,/<div>/d; /<div>/,$d' \
		| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin;
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
		# Check to see if the app itself is running
	pgrep -xq "Sharpshooter" && LAUNCH='yes' && osascript -e 'tell application "Sharpshooter" to quit'

		# Check to see if the app's agent (menu bar helper) is running
	pgrep -xq "SharpshooterAgent" && LAUNCH='yes' && osascript -e 'tell application "SharpshooterAgent" to quit'

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

if [ "$LAUNCH" = "yes" ]
then
	echo "$NAME: Launching Sharpshooter"
	open -a "Sharpshooter"
	open -a "SharpshooterAgent" || open -b com.kerlmax.SharpshooterAgent
fi

exit 0
#
#EOF
