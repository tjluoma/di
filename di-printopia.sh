#!/bin/zsh -f
# Purpose: Download and install the latest version of Printopia 2 or 3
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-07-17

NAME="$0:t:r"

V2_INSTALL_TO="$HOME/Library/PreferencePanes/Printopia.prefPane"

V3_INSTALL_TO='/Applications/Printopia.app'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

function use_v2 {

	ASTERISK='(Note that version 3 is also available.)'
	USE_VERSION='2'
	INSTALL_TO="$HOME/Library/PreferencePanes/Printopia.prefPane"
	URL="https://www.decisivetactics.com/products/printopia/dl/Printopia_2.1.23.zip"
	LATEST_VERSION="2.1.23"
}

function use_v3 {

	USE_VERSION='3'
	INSTALL_TO="/Applications/Printopia.app"

	HOMEPAGE="https://www.decisivetactics.com/products/printopia/"

		## 2018-07-17 we should get something like this:
		## https://www.decisivetactics.com/products/printopia/dl/Printopia_3.0.11.zip

	if (( $+commands[lynx] ))
	then

		URL=$(lynx -nonumbers -listonly -dump -nomargins "$HOMEPAGE" | egrep '^http.*\.zip$' | head -1)

	else

		URL=$(curl -sfL "$HOMEPAGE" \
			| tr '"' '\012' \
			| egrep "^http.*\.zip$" \
			| head -1)
	fi

	if [[ "$URL" == "" ]]
	then
		echo "$NAME: Scraping of $HOMEPAGE apparently failed. \$URL is empty."
		exit 1
	fi

	LATEST_VERSION=$(echo "$URL:t:r" | tr -dc '[0-9]\.')

	if [[ "$LATEST_VERSION" == "" ]]
	then
		echo "$NAME: Could not determine LATEST_VERSION from $URL"
		exit 1
	fi

}

        # if the user explicitly askes for version 2, use it, regardless of the above
if [ "$1" = "--use2" -o "$1" = "-2" ]
then
        use_v2
elif [ "$1" = "--use3" -o "$1" = "-3" ]
then
        use_v3
else
        if [ -e "$V2_INSTALL_TO" -a -e "$V3_INSTALL_TO" ]
        then
                echo "$NAME: Both versions 2 and 3 of Printopia are installed. I will _only_ check for updates for version 3 in this situation."
                echo "  If you want to check for updates for version 2, add the argument '--use2' i.e. '$0:t --use2' "
                echo "  To avoid this message in the future, add the argument '--use3' i.e. '$0:t --use3' "

                use_v3

        elif [ ! -e "$V2_INSTALL_TO" -a -e "$V3_INSTALL_TO" ]
        then
                        # version 2 is not installed but version 3 is
                use_v3
        elif [ -e "$V2_INSTALL_TO" -a ! -e "$V3_INSTALL_TO" ]
        then
                        # version 2 is installed but version 3 is not
                use_v2
        else
                        # neither v2 or v3 are installed
                use_v3
        fi
fi

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleShortVersionString)

	if [[ "$LATEST_VERSION" == "$INSTALLED_VERSION" ]]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION) $ASTERISK"
		exit 0
	fi

	autoload is-at-least

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	if [ "$?" = "0" ]
	then
		echo "$NAME: Up-To-Date ($LATEST_VERSION)"
		exit 0
	fi

	echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"

fi

if [[ "USE_VERSION" == "3" ]]
then
	if (( $+commands[lynx] ))
	then

		RELEASE_NOTES_URL="https://www.decisivetactics.com/products/printopia/release-notes"

		echo "$NAME: Release Notes for $INSTALL_TO:t:r:\n"

		curl -sfL "${RELEASE_NOTES_URL}" \
		| sed '1,/<div class="date">/d; /<div class="releasenotes">/,$d' \
		| lynx -dump -nomargins -width=10000 -assume_charset=UTF-8 -pseudo_inlines -stdin

		echo "\nSource: <$RELEASE_NOTES_URL>"
	fi
fi

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-$LATEST_VERSION.zip"

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

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
	&& osascript -e 'tell application "$INSTALL_TO:t:r" to quit'

	echo "$NAME: Moving existing (old) '$INSTALL_TO' to '$HOME/.Trash/'."

	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then

		echo "$NAME: failed to move existing $INSTALL_TO to $HOME/.Trash/"

		exit 1
	fi
fi

if [[ "$USE_VERSION" == "2" ]]
then

	NEW=`find "$UNZIP_TO" -iname 'Printopia.prefPane' -type d -maxdepth 5 -print`

	echo "$NAME: Installing '$NEW' to $INSTALL_TO:"

	ditto --noqtn -v "$NEW" "$INSTALL_TO"

	EXIT="$?"

	if [ "$EXIT" = "0" ]
	then

		echo "$NAME Installation/update of $INSTALL_TO successful"

	else
		echo "$NAME: ditto failed (\$EXIT = $EXIT)"

		exit 1
	fi

elif [[ "$USE_VERSION" == "3" ]]
then

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
fi

[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"

SERVER="$INSTALL_TO/Contents/MacOS/Printopia Server.app"

echo "$NAME: starting $SERVER"

open "$SERVER"

exit 0
#
#EOF
