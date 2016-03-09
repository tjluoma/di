#!/bin/zsh -f
# Purpose: download and install latest Karabiner
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2015-01-14

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

NAME="$0:t:r"

INSTALL_TO='/Applications/Karabiner.app'

INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo '0'`

XML_FEED='https://pqrs.org/osx/karabiner/files/appcast.xml'

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
	echo "$NAME: Error: bad data received:\nINFO: $INFO"
	exit 0
fi

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

FILENAME="$HOME/Downloads/Karabiner-${LATEST_VERSION}.dmg"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download failed (EXIT = $EXIT)" && exit 0

MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
		| fgrep -A 1 '<key>mount-point</key>' \
		| tail -1 \
		| sed 's#</string>.*##g ; s#.*<string>##g')

if [[ "$MNTPNT" == "" ]]
then
	echo "$NAME: MNTPNT is empty"
	exit 1
fi


if [ -e "$INSTALL_TO" ]
then
		# Quit app, if running
	pgrep -xq "Karabiner" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "Karabiner" to quit'

	# The package installer will take care of moving old version
	
fi

PKG=`find "$MNTPNT" -type f -iname \*.pkg -maxdepth 1 -print`

if [[ "$PKG" == "" ]]
then
	echo "$NAME [failed]: PKG is empty" \
	tee -a "$HOME/Desktop/$NAME.Failed.log"
	
	exit 0
fi 	

if (( $+commands[pkginstall.sh] ))
then

	pkginstall.sh "$PKG" \
	&& diskutil eject "$MNTPNT"

else

	if [ "$EUID" = "0" ]
	then
		installer -pkg "$PKG" -target / -lang en \
		&& diskutil eject "$MNTPNT"

	else
			# Try sudo but if it fails, open pkg in Finder
		sudo installer -pkg "$PKG" -target / -lang en \
		&& diskutil eject "$MNTPNT" \
		|| open -R "$PKG"
	fi 	
fi

open -a Karabiner

exit 0

#
#EOF
