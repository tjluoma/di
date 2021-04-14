#!/usr/bin/env zsh -f
# Purpose: Download latest version of Pretzel from <https://www.amie-chen.com/pretzel/>
# Note: Only works with a small handful of apps: <https://www.amie-chen.com/pretzel/supported-apps>
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-08-19

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

NAME="$0:t:r"

INSTALL_TO="/Applications/Pretzel.app"

HOMEPAGE="https://www.amie-chen.com/pretzel/"

DOWNLOAD_PAGE="https://github.com/amiechen/pretzel/releases"

SUMMARY="Pretzel is Mac desktop app that shows and find keyboard shortcuts based on your current app."

LATEST_VERSION_URL=$(curl -sfLS --head 'https://github.com/amiechen/pretzel/releases/latest' | awk -F' |\r' '/^.ocation:/{print $2}')

RELEASE_NOTES_URL="$LATEST_VERSION_URL"

LATEST_VERSION=$(echo "$LATEST_VERSION_URL:t" | tr -dc '[0-9]\.')

URL=$(curl -sfLS "$LATEST_VERSION_URL" \
		| egrep '/amiechen/pretzel/releases/download/.*-mac.zip' \
		| awk -F'"' '//{print "https://github.com"$2}')

	# If any of these are blank, we should not continue
if [ "$URL" = "" -o "$LATEST_VERSION" = "" ]
then
	echo "$NAME: Error: bad data received:
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	"

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

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}.zip"

if (( $+commands[lynx] ))
then

	( echo "$NAME: Release Notes for $INSTALL_TO:t:r ($LATEST_VERSION):\n" ;
		curl -sfL "$RELEASE_NOTES_URL" \
		| sed '1,/<div class="markdown-body">/d; /<\/div>/,$d' \
		| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin ;
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

# https://github.com/amiechen/pretzel/releases/download/v0.6.1/Pretzel-0.6.1.dmg
#
# curl -sfLS 'https://download.pretzel.rocks/latest-mac.json'
# {
#   "version": "0.0.19",
#   "releaseDate": "2018-07-20T17:21:53.460Z",
#   "url": "https://download.pretzel.rocks/Pretzel-0.0.19-mac.zip"
# }
#
# That release date looks recent, but the version number is very old.
#EOF
