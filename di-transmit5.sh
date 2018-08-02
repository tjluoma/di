#!/bin/zsh -f
# Purpose: Download and install the latest version of Transmit 5
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-07-19

NAME="$0:t:r"

INSTALL_TO='/Applications/Transmit.app'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

	# found via "/usr/local/Homebrew/Library/Taps/homebrew/homebrew-cask/Casks/transmit.rb"
CHANGELOG="https://library.panic.com/releasenotes/transmit5"

	# Web-Scraping. Obviously very fragile and prone to breaking if the format of the page changes,
	# but there's no appcast, at least none that I can find
LATEST_VERSION=$(curl --silent --fail --location "$CHANGELOG" \
				| fgrep '<h2 id="' \
				| head -1 \
				| sed 's#</h2>##g ; s#.*>##g')

if [[ "$LATEST_VERSION" == "" ]]
then
		# check to see if the page still exists
	HTTP_CODE=$(curl --silent --location --head "$CHANGELOG" \
				| awk -F' ' '/^HTTP/{print $2}' \
				| tail -1)

	if [[ "$HTTP_CODE" == "200" ]]
	then
			# Page does exist
		echo "$NAME: \$LATEST_VERSION is empty. Check \"$CHANGELOG\" for format changes."
	else
			# Page does NOT exist
		echo "$NAME: $CHANGELOG not found: HTTP_CODE = $HTTP_CODE"
	fi

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleShortVersionString)

	if [[ "$LATEST_VERSION" == "$INSTALLED_VERSION" ]]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION)"
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

	# This also depends on the format of their download URLs not changing
	# as of 2018-07-19, all of these URL formats seem to work but redirect:
	#
	# "https://www.panic.com/transmit/d/Transmit%20${LATEST_VERSION}.zip"
	# 302 ->
	# "Location: https://panic.com/download/transmit/Transmit%20${LATEST_VERSION}.zip"
	# 302 ->
	# "Location: https://download.panic.com/transmit/Transmit%20${LATEST_VERSION}.zip"

URL="https://download.panic.com/transmit/Transmit%20${LATEST_VERSION}.zip"

	# So let's quickly test to make sure it's valid
HTTP_CODE=$(curl --silent --location --head "$URL" \
			| awk -F' ' '/^HTTP/{print $2}' \
			| tail -1)

if [[ "$HTTP_CODE" != "200" ]]
then
		# Download URL does NOT exist
	echo "$NAME: \"$URL\" not found: HTTP_CODE = $HTTP_CODE"
	exit 1
fi

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}.zip"

echo "$NAME: Downloading \"$URL\" to \"$FILENAME\":"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

UNZIP_TO=$(mktemp -d "${TMPDIR-/tmp/}${NAME}-XXXXXXXX")

echo "$NAME: Unzipping $FILENAME to $UNZIP_TO:"

ditto --noqtn -xk "$FILENAME" "$UNZIP_TO"

EXIT="$?"

if [[ "$EXIT" == "0" ]]
then
	echo "$NAME: Unzip successful"
else
		# failed
	echo "$NAME failed (ditto --noqtn -xkv \"$FILENAME\" \"$UNZIP_TO\")"

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

echo "$NAME: Moving new version of \"$INSTALL_TO:t\" (from \"$UNZIP_TO\") to \"$INSTALL_TO\"."

	# Move the file out of the folder
mv -vn "$UNZIP_TO/$INSTALL_TO:t" "$INSTALL_TO"

EXIT="$?"

if [[ "$EXIT" = "0" ]]
then

	echo "$NAME: Successfully installed \"$UNZIP_TO/$INSTALL_TO:t\" to \"$INSTALL_TO\"."

else
	echo "$NAME: Failed to move \"$UNZIP_TO/$INSTALL_TO:t\" to \"$INSTALL_TO\"."

	exit 1
fi


exit 0
#
#EOF
