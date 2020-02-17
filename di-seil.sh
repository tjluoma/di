#!/usr/bin/env zsh -f
# Purpose: Download and install the latest version of Seil, which is no longer developed: <https://pqrs.org/osx/karabiner/seil.html>
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-14

NAME="$0:t:r"

INSTALL_TO='/Applications/Seil.app'

HOMEPAGE="https://pqrs.org/osx/karabiner/seil.html"

DOWNLOAD_PAGE="https://pqrs.org/osx/karabiner/seil.html"

SUMMARY="Utility for the caps lock key and some international keys in PC keyboards. (macOS Sierra users: Seil functions are integraded to Karabiner-Elements. Please use Karabiner-Elements.)"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

XML_FEED='https://pqrs.org/osx/karabiner/files/seil-appcast.xml'

# XML_FEED='https://pqrs.org/osx/karabiner/files/seil-appcast-devel.xml'

# only sparkle:version is in the feed

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

	INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo '0'`

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

# No RELEASE_NOTES_URL since it's EOL

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-$LATEST_VERSION.dmg"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
		| fgrep -A 1 '<key>mount-point</key>' \
		| tail -1 \
		| sed 's#</string>.*##g ; s#.*<string>##g')

PKG=`find "$MNTPNT" -iname \*.pkg -maxdepth 1 -print | head -1`

if (( $+commands[pkginstall.sh] ))
then
	pkginstall.sh "$PKG"

else
	sudo /usr/sbin/installer -pkg "$PKG" -target / -lang en || open -R "$PKG"
fi

if (( $+commands[unmount.sh] ))
then
	unmount.sh "$MNTPNT"
else
	diskutil eject "$MNTPNT"
fi

exit 0
#EOF
