#!/bin/zsh -f
# Purpose: download and install HandBrake nightly
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2014-08-18

NAME="$0:t:r"

INSTALL_TO='/Applications/HandBrake Nightly.app'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

## HandBrake has a Sparkle feed, but it seems vastly out of date
# XML_FEED='https://handbrake.fr/appcast_unstable.x86_64.xml'


UA='curl/7.21.7 (x86_64-apple-darwin10.8.0) libcurl/7.21.7 OpenSSL/1.0.0d zlib/1.2.5 libidn/1.22'


if ((! $+commands[lynx] ))
then
	# note: if lynx is a function or alias, it will come back not found

	echo "$NAME: lynx is required but not found in $PATH"
	exit 1
fi

URL=`lynx -listonly -dump -nomargins -nonumbers 'http://handbrake.fr/nightly.php' | fgrep -i .dmg | fgrep -iv "CLI"`

LATEST_VERSION=`echo "$URL:t:r" | sed 's#HandBrake-##g; s#-osx##g'`

	# If any of these are blank, we should not continue
if [ "$LATEST_VERSION" = "" -o "$URL" = "" ]
then
	echo "$NAME: Error: bad data received:
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	"

	exit 1
fi

INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null | awk '{print $1}' || echo '1.0.0'`

if [[ "$LATEST_VERSION" == "$INSTALLED_VERSION" ]]
then
		# No Update Needed
	echo "$NAME: Up-To-Date (Installed: $INSTALLED_VERSION and Latest: $LATEST_VERSION)"
	exit 0
fi

echo "$NAME: Out of Date: $INSTALLED_VERSION vs $LATEST_VERSION"

FILENAME="$HOME/Downloads/$URL:t"

echo "$NAME: Downloading $URL to $FILENAME"

curl -A "$UA" --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0


MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
		| fgrep -A 1 '<key>mount-point</key>' \
		| tail -1 \
		| sed 's#</string>.*##g ; s#.*<string>##g')


if [ -e "$INSTALL_TO" ]
then

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/HandBrake.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

ditto --noqtn -v "$MNTPNT/HandBrake.app" "$INSTALL_TO"


EXIT="$?"

if [ "$EXIT" = "0" ]
then

	echo "$NAME: Successfully updated/installed $INSTALL_TO"

else
	echo "$NAME: ditto failed (\$EXIT = $EXIT)"

	exit 1
fi

diskutil eject "$MNTPNT"


exit 0

#
#EOF
