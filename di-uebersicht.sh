#!/usr/bin/env zsh -f
# Purpose: Download and install the latest version of Übersicht from <https://github.com/felixhageloh/uebersicht>
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2016-01-19, updated and verified 2018-08

NAME="$0:t:r"

	# This is where the app will be installed or updated.
if [[ -d '/Volumes/Applications' ]]
then
	INSTALL_TO='/Volumes/Applications/Übersicht.app'
	TRASH="/Volumes/Applications/.Trashes/$UID"
else
	INSTALL_TO='/Applications/Übersicht.app'
	TRASH="/.Trashes/$UID"
fi

[[ ! -w "$TRASH" ]] && TRASH="$HOME/.Trash"

HOMEPAGE="http://tracesof.net/uebersicht/"

DOWNLOAD_PAGE="https://github.com/felixhageloh/uebersicht/releases"

SUMMARY="Übersicht lets you run system commands and display their output on your desktop in little containers, called widgets. Widgets are written using HTML5, which means they: are easy to write and customize, can show data in tables, charts, graphs ... you name it, can react to different screen sizes."

LAUNCH='no'

# CONVERTED_APPNAME="$(iconv -t MAC <<< $INSTALL_TO:t:r)"		# See note below

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

# Note that /Applications/Übersicht.app reports its version info like this:
# 	CFBundleShortVersionString: 1.2
# 	CFBundleVersion: 53
#
# but in the XML_FEED we get:
#
# 	sparkle:version="53"
# 	sparkle:shortVersionString="1.2.53"

XML_FEED="https://raw.githubusercontent.com/felixhageloh/uebersicht/gh-pages/updates.xml.rss"

INFO=($(curl -sfL $XML_FEED \
		| tr ' ' '\012' \
		| egrep '^(url|sparkle:shortVersionString)=' \
		| head -2 \
		| sort \
		| awk -F'"' '//{print $2}'))

LATEST_VERSION="$INFO[1]"

URL="$INFO[2]"

if [[ -e "$INSTALL_TO" ]]
then
		# We need to get both 'INSTALLED_VERSION' and 'INSTALLED_BUILD' and put them together
	INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString`

	INSTALLED_BUILD=`defaults read "$INSTALL_TO/Contents/Info" CFBundleVersion`

		# now we meld them into one:
	INSTALLED_VERSION="$INSTALLED_VERSION.$INSTALLED_BUILD"

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

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

	## make sure that the .zip is valid before we proceed
(command unzip -l "$FILENAME" 2>&1 )>/dev/null

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: '$FILENAME' is a valid zip file."

else
	echo "$NAME: '$FILENAME' is an invalid zip file (\$EXIT = $EXIT)"

	mv -fv "$FILENAME" "$TRASH/"

	mv -fv "$FILENAME:r".* "$TRASH/"

	exit 0

fi

## unzip to a temporary directory
UNZIP_TO=$(mktemp -d "${TRASH}/${NAME}-XXXXXXXX")

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

	echo "$NAME: Moving existing (old) '$INSTALL_TO' to '$TRASH/'."

	mv -vf "$INSTALL_TO" "$TRASH/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then

		echo "$NAME: failed to move existing '$INSTALL_TO' to '$TRASH'."

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
