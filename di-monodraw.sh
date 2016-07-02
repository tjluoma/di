#!/bin/zsh -f
# Purpose: 
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2016-01-19

NAME="$0:t:r"
APPNAME="Monodraw"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

INSTALL_TO="/Applications/$APPNAME.app"
# echo $INSTALL_TO

INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo '0'`
BUILD_NUMBER=`defaults read "$INSTALL_TO/Contents/Info" CFBundleVersion 2>/dev/null || echo 600000`
# echo $INSTALLED_VERSION
# echo $BUILD_NUMBER
FEED_URL="http://updates.helftone.com/monodraw/appcast-beta.xml"

INFO=($(curl -sfL $FEED_URL \
| tr ' ' '\012' \
| egrep '^(url|sparkle:shortVersionString|sparkle:version)=' \
| head -3 \
| awk -F'"' '//{print $2}'))
# echo $INFO

URL="$INFO[1]"
# echo $URL
LATEST_BUILD="$INFO[2]"
# echo $LATEST_BUILD
LATEST_VERSION="$INFO[3]"
# echo $LATEST_VERSION

if [[ "$LATEST_BUILD" == "$BUILD_NUMBER" ]]
 then
 	echo "$NAME: Up-To-Date ($BUILD_NUMBER)"
 	exit 0
fi

autoload is-at-least

is-at-least "$LATEST_BUILD" "$BUILD_NUMBER"

if [ "$?" = "0" ]
 then
 	echo "$NAME: Installed version ($BUILD_NUMBER) is ahead of official version $LATEST_BUILD"
 	exit 0
 fi
 
 echo "$NAME: Outdated (Installed = $BUILD_NUMBER vs Latest = $LATEST_BUILD)"


FILENAME="$HOME/Downloads/${APPNAME//[[:space:]]/}-b${LATEST_BUILD}.zip"


echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

if [ -e "$INSTALL_TO" ]
then
	pgrep -qx "$APPNAME" && LAUNCH='yes' && killall "$APPNAME"
	mv -f "$INSTALL_TO" "$HOME/.Trash/$APPNAME.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

	# Extract from the .zip file and install (this will leave the .zip file in place)
ditto --noqtn -xk "$FILENAME" "$INSTALL_TO:h/"

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: Installation of $INSTALL_TO was successful."
	
	[[ "$LAUNCH" == "yes" ]] && open -a "$INSTALL_TO"
	
else
	echo "$NAME: Installation of $INSTALL_TO failed (\$EXIT = $EXIT)\nThe downloaded file can be found at $FILENAME."
fi




exit 0
EOF