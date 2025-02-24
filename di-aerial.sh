#!/usr/bin/env zsh -f
# Purpose: 	Download and install the latest version of the Aerial screen saver
#
# From:		Timothy J. Luoma
# Mail:		luomat at gmail dot com
# Date:		2018-09-05
# Verified:	2025-02-24

# This is an odd one, because the best way to install the screensaver is
# to install a companion app. So we need to check one thing, and install
# another. Which seems like it's bound to have issues. But we'll try it.

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

if [[ -d "$HOME/Library/Screen Savers/Aerial.saver" ]]
then
		# if the user has it installed, use that
	INSTALL_TO="$HOME/Library/Screen Savers/Aerial.saver"

elif [[ -d "/Library/Screen Savers/Aerial.saver" ]]
then
		# if there is already a system-wide installation, use that
	INSTALL_TO="/Library/Screen Savers/Aerial.saver"
else
		# if neither is install, do a local install
	INSTALL_TO="$HOME/Library/Screen Savers/Aerial.saver"

fi

XML_FEED='https://github.com/JohnCoates/Aerial/releases.atom'

HOMEPAGE="https://github.com/JohnCoates/Aerial/"

DOWNLOAD_PAGE="https://github.com/JohnCoates/Aerial/releases/latest"

SUMMARY="Apple TV Aerial Screensaver for Mac."

LATEST_RELEASE_URL=$(curl -sfLS --head "$DOWNLOAD_PAGE" \
				| awk -F' |\r' '/^.ocation:/{print $2}' \
				| tail -1)

LATEST_VERSION=$(echo "$LATEST_RELEASE_URL:t" | tr -dc '[0-9]\.')

URL='https://github.com/glouel/AerialCompanion/releases/latest/download/Aerial.Companion.zip'

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

	# if the companion app is already there, launch it
if [[ -e "/Applications/Aerial Companion.app" ]]
then
	echo "$NAME: Launching '/Applications/Aerial Companion.app'..."
	exit 0
fi


	# If the companion app is not found, download and install it

FILENAME="$HOME/Downloads/Aerial.Companion.zip"

if (( $+commands[lynx] ))
then

	## Yes, we need to call lynx twice here

	( echo "$NAME: Release Notes for $INSTALL_TO:t:r ($LATEST_VERSION):" ;
	curl -sfLS "$XML_FEED" \
	| awk '/<content/{i++}i==1' \
	| sed '/<author>/,$d' \
	| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin \
	| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin ) \
	| tee "$FILENAME:r.txt"

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

	# Move the Companion app to the Applications folder
mv -vn "$UNZIP_TO/Aerial Companion.app" "/Applications/Aerial Companion.app"

EXIT="$?"

if [[ "$EXIT" == "0" ]]
then

	echo "$NAME: Successfully moved '$UNZIP_TO/Aerial Companion.app' to '/Applications/Aerial Companion.app'..."

else

	echo "$NAME: 'mv' failed (\$EXIT = $EXIT)"

	exit 1
fi

open -a "/Applications/Aerial Companion.app"

exit 0
#EOF
