#!/bin/zsh -f
# Purpose: download and install Alfred 3, or update it if already installed
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-07-17

NAME="$0:t:r"

INSTALL_TO='/Applications/Alfred 3.app'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

LAUNCH='no'

if [ -e "$HOME/.di-alfred-prefer-betas" ]
then
		## this is for betas
		## create a file (which can be empty) at
		## $HOME/.di-alfred-prefer-betas
		## to tell this script to look for betas
	XML_FEED='https://www.alfredapp.com/app/update/prerelease.xml'
	CHANNEL='Beta'

else
		## This is for official, non-beta versions
	XML_FEED='https://www.alfredapp.com/app/update/general.xml'
	CHANNEL='Official (Non-Beta)'
fi

echo -n "$NAME: Checking for ${CHANNEL} updates: "

INFO=$(curl -sfL "$XML_FEED" \
	| egrep -A1 '<key>(version|build|location)</key>')

MAJOR_VERSION=$(echo "$INFO" | fgrep -A1 '<key>version</key>' | tr -dc '[0-9]\.')

	# aka "Build" in the XML_FEED or "CFBundleVersion" in the .app itself
LATEST_VERSION=$(echo "$INFO" | fgrep -A1 '<key>build</key>' | tr -dc '[0-9]')

URL=$(echo "$INFO" | fgrep -A1 '<key>location</key>' | fgrep 'https://' | sed 's#.*<string>##g ; s#</string>.*##g')

	# If any of these are blank, we should not continue
if [ "$INFO" = "" -o "$LATEST_VERSION" = "" -o "$URL" = "" -o "$MAJOR_VERSION" = "" ]
then
	echo "$NAME: Error: bad data received:
	INFO: $INFO
	LATEST_VERSION: $LATEST_VERSION
	MAJOR_VERSION: $MAJOR_VERSION
	URL: $URL
	"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

		# Note that we are using the Build Number/CFBundleVersion for Alfred,
		# because that changes more often than the CFBundleShortVersionString
	INSTALLED_VERSION=$(defaults read "$INSTALL_TO/Contents/Info" CFBundleVersion 2>/dev/null)

	if [[ "$LATEST_VERSION" == "$INSTALLED_VERSION" ]]
	then
		echo "$NAME: Up-To-Date ($MAJOR_VERSION/$INSTALLED_VERSION)"
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

## Release Notes BEGIN
## Release notes for Alfred do not require lynx

	RELEASE_NOTES_URL="$XML_FEED"

	echo "$NAME: Release Notes for $INSTALL_TO:t:r version $LATEST_VERSION:\n"

	curl -sfL "$RELEASE_NOTES_URL" \
	| sed "1,/^## Alfred $LATEST_VERSION/d; /^## /,\$d"

	echo "\nSource: XML_FEED <$RELEASE_NOTES_URL>"

## Release Notes END

FILENAME="$HOME/Downloads/Alfred-${MAJOR_VERSION}-${LATEST_VERSION}.zip"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

if [[ -e "$INSTALL_TO" ]]
then
		# Quit app, if running
	pgrep -xq "Alfred 3" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "Alfred 3" to quit'

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/Alfred 3.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

ditto --noqtn -xk "$FILENAME" "$INSTALL_TO:h/"

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: Successfully installed $FILENAME to $INSTALL_TO:h"

	[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"

else
	echo "$NAME: failed to install $FILENAME to $INSTALL_TO:h (ditto \$EXIT = $EXIT)"

	exit 1
fi

exit 0
#EOF
