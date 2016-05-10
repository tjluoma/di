#!/bin/zsh
# Download and install ImageOptim
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-04-26

NAME="$0:t:r"

# wget -c http://dl.macupdate.com/prod/ImageOptim.zip
# https://imageoptim.com/ImageOptim1.6.1a1.tar.bz2

XML_FEED='https://imageoptim.com/appcast-test.xml'

# XML_FEED='https://imageoptim.com/appcast.xml'

INSTALL_TO='/Applications/ImageOptimBeta.app'

INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo '0'`
 
INFO=($(curl -sfL "$XML_FEED" \
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
	echo "$NAME: Error: bad data received:\nINFO: $INFO"
	exit 0
fi

if [[ "$LATEST_VERSION" == "$INSTALLED_VERSION" ]]
then
	echo "$NAME: Up-To-Date (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"
	exit 0
fi

echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}.tar.bz2"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download failed (EXIT = $EXIT)" && exit 0


if [ -e "$INSTALL_TO" ]
then
		# Quit app, if running
	pgrep -xq "ImageOptim" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "ImageOptim" to quit'

		# move installed version to trash 
	mv -vf "$INSTALL_TO" "$HOME/.Trash/ImageOptim.$INSTALLED_VERSION.$$.app"
fi


TEMPDIR=`mktemp -d "${TMPDIR-/tmp/}XXXXXXXX"`

tar -x -C "${TEMPDIR}" -j -f "$FILENAME"

mv -vf "$TEMPDIR/ImageOptim.app" "$INSTALL_TO"

rmdir "$TEMPDIR"	# Cleanup 


exit
#
#EOF

