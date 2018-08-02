#!/bin/zsh -f
# Purpose: Download and install the latest version of ImageOptim BETA
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-04-26

NAME="$0:t:r"

	# Note that we are installing this in a different path/name so it won't conflict with the non-beta version 
INSTALL_TO='/Applications/ImageOptimBeta.app'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi


# wget -c http://dl.macupdate.com/prod/ImageOptim.zip
# https://imageoptim.com/ImageOptim1.6.1a1.tar.bz2

# XML_FEED='https://imageoptim.com/appcast.xml'

XML_FEED='https://imageoptim.com/appcast-test.xml'

INFO=($(curl -sfL "$XML_FEED" \
		| tr -s ' ' '\012' \
		| egrep 'sparkle:version=|url=' \
		| head -2 \
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

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}.tar.bz2"

echo "$NAME: Downloading $URL to $FILENAME"

 curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download failed (EXIT = $EXIT)" && exit 0

if [[ -e "$INSTALL_TO" ]]
then
		## Quit app, if running
		# 	pgrep -xq "ImageOptim" \
		# 	&& LAUNCH='yes' \
		# 	&& osascript -e 'tell application "ImageOptim" to quit'

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/ImageOptim.$INSTALLED_VERSION.$$.app"
fi

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

mv -vf "$TEMPDIR/ImageOptim.app" "$INSTALL_TO"

EXIT="$?"

if [ "$EXIT" = "0" ]
then

	echo "$NAME: Successfully installed $TEMPDIR/ImageOptim.app to $INSTALL_TO"

else
	echo "$NAME: 'mv' failed (\$EXIT = $EXIT)"

	exit 1
fi

rmdir "$TEMPDIR"

exit 0
#
#EOF

