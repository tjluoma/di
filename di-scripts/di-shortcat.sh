#!/bin/zsh -f
# Purpose:
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2015-06-01

NAME="$0:t:r"

XML_FEED='https://shortcatapp.com/updates/appcast.xml'

INSTALL_TO='/Applications/Shortcat.app'

INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo 0`

INFO=($(curl -sfL "$XML_FEED" | tr -s ' ' '\012' | egrep '(url=|sparkle:shortVersionString=)' | head -2 | awk -F'"' '//{print $2}'))

URL_RAW=`echo "$INFO[1]" | sed 's#&amp\;#\&#g' `

URL=`curl -sfL --head "$URL_RAW" | awk -F' ' '/^Location:/{print $NF}' | tr -d '\r' `

LATEST_VERSION="$INFO[2]"

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

FILENAME="$HOME/Downloads/Shortcat-$LATEST_VERSION.zip"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

LAUNCH='no'

if [ -e "$INSTALL_TO" ]
then
		# Quit app if running
	pgrep -xq Shortcat && LAUNCH='yes' && osascript -e 'tell application "Shortcat" to quit'

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $FILE to $INSTALL_TO"

ditto --noqtn -xk "$FILENAME" "$INSTALL_TO:h"

[[ "$LAUNCH" == "yes" ]] && open -a Shortcat

exit 0

#
#EOF
