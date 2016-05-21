#!/bin/zsh -f
# Purpose: Download and install Tower 2
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2015-02-02

# @NOTDONE

NAME="$0:t:r"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

OS_VER=`sw_vers -productVersion`

INFO=($(curl -sfL "https://updates.fournova.com/updates/tower2-mac/stable/?os_version=$OS_VER" \
| tr -s ' ' '\012' \
| egrep '^(url|sparkle:shortVersionString)=' \
| head -2 \
| awk -F'"' '//{print $2}'))

URL="$INFO[1]"

LATEST_VERSION="$INFO[2]"

INSTALL_TO="/Applications/Tower.app"

INSTALLED_VERSION=`defaults read $INSTALL_TO/Contents/Info CFBundleShortVersionString 2>/dev/null || echo '0'`

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

FILENAME="$HOME/Downloads/Tower-${LATEST_VERSION}.zip"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

if [[ -e "$INSTALL_TO" ]]
then
	mv -vn "$INSTALL_TO" "$HOME/.Trash/Tower.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

ditto --noqtn -xk "$FILENAME" "$INSTALL_TO:h/"


exit 0

#
#EOF
