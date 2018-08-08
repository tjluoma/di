#!/bin/zsh -f
# Purpose: Download and install the latest version of iTerm (note that a separate script exists for "nightly" builds)
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2016-01-19, updated 2018-08-02

NAME="$0:t:r"

INSTALL_TO="/Applications/iTerm.app"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

	# if you want the nightly versions, see:
	# https://github.com/tjluoma/di/blob/master/di-iterm-nightly.sh
XML_FEED="https://iterm2.com/appcasts/final.xml"

	# 'CFBundleVersion' and 'CFBundleShortVersionString' are identical in app, but only one is in XML_FEED
INFO=($(curl -sfL "$XML_FEED" \
		| tr ' ' '\012' \
		| egrep '^(url|sparkle:version)=' \
		| tail -2 \
		| sort \
		| awk -F'"' '//{print $2}'))

LATEST_VERSION="$INFO[1]"

URL="$INFO[2]"

# echo "
# LATEST_VERSION: $LATEST_VERSION
# URL: $URL
# "

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString`

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

## Release Notes - start
# This always seems to be a plain-text file, but the filename itself changes
RELEASE_NOTES_URL=$(curl -sfL "$XML_FEED" \
	| sed "1,/<title>Version $LATEST_VERSION<\/title>/d; /<\/sparkle:releaseNotesLink>/,\$d ; s#<sparkle:releaseNotesLink>##g" \
	| awk -F' ' '/https/{print $1}')

echo -n "$NAME: Release Notes for "

curl -sfL "$RELEASE_NOTES_URL"

echo "\nSource: <$RELEASE_NOTES_URL>"
## Release Notes - end

FILENAME="$HOME/Downloads/${INSTALL_TO:t:r}-${LATEST_VERSION}.zip"

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

if [ -e "$INSTALL_TO" ]
then
		# don't kill the app because it might be running this script. Oops.
	mv -f "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

	# Extract from the .zip file and install (this will leave the .zip file in place)
ditto --noqtn -xk "$FILENAME" "$INSTALL_TO:h/"

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: Installation of $INSTALL_TO was successful."
else
	echo "$NAME: Installation of $INSTALL_TO failed (\$EXIT = $EXIT)\nThe downloaded file can be found at $FILENAME."
fi

exit 0
EOF
