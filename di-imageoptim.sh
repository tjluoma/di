#!/bin/zsh -f
# Purpose: Download and install ImageOptim from <https://imageoptim.com>
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-04-26

NAME="$0:t:r"

	# This is where the app will be installed or updated.
if [[ -d '/Volumes/Applications' ]]
then
	INSTALL_TO='/Volumes/Applications/ImageOptim.app'
else
	INSTALL_TO='/Applications/ImageOptim.app'
fi

HOMEPAGE="https://imageoptim.com/mac"

DOWNLOAD_PAGE="https://imageoptim.com/ImageOptim.tbz2"

SUMMARY="ImageOptim makes images load faster. Removes bloated metadata. Saves disk space & bandwidth by compressing images without losing quality."

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

	# if you want to install beta releases
	# create a file (empty, if you like) using this file name/path:
PREFERS_BETAS_FILE="$HOME/.config/di/imageoptim-prefer-betas.txt"

if [[ -e "$PREFERS_BETAS_FILE" ]]
then
		# This is for betas
	XML_FEED='https://imageoptim.com/appcast-test.xml'
	NAME="$NAME (beta releases)"
else
		## This is for official, non-beta versions
	XML_FEED='https://imageoptim.com/appcast.xml'
fi

RELEASE_NOTES_URL="$XML_FEED"

	# FYI - CFBundleShortVersionString and CFBundleVersion are identical in the app
INFO=($(curl -sfL "$XML_FEED" \
		| egrep 'sparkle:version=|url=' \
		| fgrep -vi 'delta' \
		| tr -s ' ' '\012' \
		| egrep 'sparkle:version=|url=' \
		| tail -2 \
		| sort \
		| awk -F'"' '/^/{print $2}'))

	# "Sparkle" will always come before "url" because of "sort"
LATEST_VERSION="$INFO[1]"

URL="$INFO[2]"

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

	INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString `

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

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}.tbz2"

if (( $+commands[lynx] ))
then

	(echo "$NAME: Release Notes for $INSTALL_TO:t:r ($LATEST_VERSION):\n" ;
		curl -sSfL "$RELEASE_NOTES_URL" \
		| sed '1,/<description><\!\[CDATA\[/d; /\]\]><\/description>/,$d' \
		| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin ;
		echo "\nSource: XML_FEED <$RELEASE_NOTES_URL>" ) | tee "$FILENAME:r.txt"
fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

TEMPDIR=`mktemp -d "${TMPDIR-/tmp/}XXXXXXXX"`

## I am installing into a temp directory so that I can use my own custom INSTALL_TO name rather than overwriting the non-beta version

echo "$NAME: Extracting $FILENAME to $TEMPDIR..."

tar -x -C "${TEMPDIR}" -j -f "$FILENAME"

EXIT="$?"

if [ "$EXIT" != "0" ]
then

	echo "$NAME: 'tar' failed (\$EXIT = $EXIT)"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then
		## Quit app, if running
	pgrep -xq "$INSTALL_TO:t:r" \
	&& LAUNCH='yes' \
	&& osascript -e "tell application \"$INSTALL_TO:t:r\" to quit"

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$INSTALL_TO:h/.Trashes/$UID/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"
fi

mv -vf "$TEMPDIR/$INSTALL_TO:t" "$INSTALL_TO"

EXIT="$?"

if [ "$EXIT" = "0" ]
then

	echo "$NAME: Successfully installed $TEMPDIR/$INSTALL_TO:t to $INSTALL_TO"

else
	echo "$NAME: 'mv' failed (\$EXIT = $EXIT)"

	exit 1
fi

rmdir "$TEMPDIR"

[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"

exit 0
#
#EOF

