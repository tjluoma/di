#!/usr/bin/env zsh -f
# Purpose: 	Download and install the latest version of Übersicht from <https://github.com/felixhageloh/uebersicht>
#
# From:		Timothy J. Luoma
# Mail:		luomat at gmail dot com
# Date:		2016-01-19, updated and verified 2018-08
# Verified:	2025-02-22

NAME="$0:t:r"
INSTALL_TO="/Applications/Übersicht.app"

HOMEPAGE="http://tracesof.net/uebersicht/"

DOWNLOAD_PAGE="https://github.com/felixhageloh/uebersicht/releases"

SUMMARY="Übersicht lets you run system commands and display their output on your desktop in little containers, called widgets. Widgets are written using HTML5, which means they: are easy to write and customize, can show data in tables, charts, graphs ... you name it, can react to different screen sizes."

LAUNCH='no'

# CONVERTED_APPNAME="$(iconv -t MAC <<< $INSTALL_TO:t:r)"		# See note below

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
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

UNZIP_TO=$(mktemp -d "${TMPDIR-/tmp/}${NAME}-XXXXXXXX")

echo "$NAME: Unzipping '$FILENAME' to '$UNZIP_TO':"

ditto -xk --noqtn "${FILENAME}" "${UNZIP_TO}"

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

	## I couldn't get this to work, but the 'osascript' line does quit the app,
	## so I'm suggesting that instead.
	# pgrep -qx "$CONVERTED_APPNAME" && LAUNCH='yes' && killall "$CONVERTED_APPNAME"

	IS_RUNNING=`ps auxwww | egrep '.bersicht' | fgrep -v egrep`

	if [[ "$IS_RUNNING" != "" ]]
	then
		echo "$NAME: Quitting Übersicht"

		osascript -e 'tell application "Übersicht" to quit'

		sleep 5 # give it a chance to clean up

		LAUNCH='yes'
	fi

	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.$RANDOM.app"

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

	[[ "$LAUNCH" == "yes" ]] && open -a "$INSTALL_TO" && echo "$NAME: launching ${INSTALL_TO}."

else
	echo "$NAME: Failed to move '$UNZIP_TO/$INSTALL_TO:t' to '$INSTALL_TO'."

	exit 1
fi

exit 0
EOF
