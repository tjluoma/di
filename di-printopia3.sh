#!/bin/zsh -f
# Purpose: Download and install the latest version of Printopia 3
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-07-17

NAME="$0:t:r"

INSTALL_TO='/Applications/Printopia.app'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

HOMEPAGE="https://www.decisivetactics.com/products/printopia/"


	## 2018-07-17 we should get something like this:
	## https://www.decisivetactics.com/products/printopia/dl/Printopia_3.0.11.zip

URL=$(curl -sfL "$HOMEPAGE" \
| tr '"' '\012' \
| egrep "^https://www.decisivetactics.com/products/printopia/dl/Printopia_.*\.zip$" \
| head -1)

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

if (( $+commands[lynx] ))
then

	RELEASE_NOTES_URL="https://www.decisivetactics.com/products/printopia/release-notes"

	echo "$NAME: Release Notes for $INSTALL_TO:t:r:\n"

	curl -sfL "${RELEASE_NOTES_URL}" \
	| sed '1,/<div class="date">/d; /<div class="releasenotes">/,$d' \
	| lynx -dump -nomargins -nonumbers -width=10000 -assume_charset=UTF-8 -pseudo_inlines -stdin

	echo "\nSource: <$RELEASE_NOTES_URL>"

fi

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-$LATEST_VERSION.zip"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download failed (EXIT = $EXIT)" && exit 0

## Move old version, if any

if [[ -e "$INSTALL_TO" ]]
then
	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO"

	# Extract from the .zip file and install (this will leave the .zip file in place)
ditto --noqtn -xk "$FILENAME" "$INSTALL_TO:h/"

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: Installation of $INSTALL_TO was successful."

else
	echo "$NAME: Installation of $INSTALL_TO failed (\$EXIT = $EXIT)\nThe downloaded file can be found at $FILENAME."

	exit 1
fi

exit 0
#
#EOF

