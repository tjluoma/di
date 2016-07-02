#!/bin/zsh -f
# Download and install Flux
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-10-28

NAME="$0:t:r"
APPNAME="Flux"

INSTALL_TO='/Applications/Flux.app'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

LAUNCH='no'

INFO=($(curl -sfL 'https://justgetflux.com/mac/macflux.xml' | tr -s ' ' '\012' | egrep '^(url|sparkle:version)=' | head -2 | awk -F'"' '//{print $2}'))

URL="$INFO[1]"

LATEST_VERSION="$INFO[2]"

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

FILENAME="$HOME/Downloads/$APPNAME-$LATEST_VERSION.zip"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

if [ -e "$INSTALL_TO" ]
then
	pgrep -qx "$APPNAME" && LAUNCH='yes' && killall -9 "$APPNAME"
	mv -f "$INSTALL_TO" "$HOME/.Trash/$APPNAME.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

ditto --noqtn -xk "$FILENAME" "$INSTALL_TO:h/"

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: Installation of $INSTALL_TO was successful."
	
	[[ "$LAUNCH" == "yes" ]] && open -a "$INSTALL_TO"
	
else
	echo "$NAME: Installation of $INSTALL_TO failed (\$EXIT = $EXIT)\nThe downloaded file can be found at $FILENAME."
fi

[[ "$LAUNCH" = "yes" ]] && echo "$NAME: relaunching $APPNAME" && open --background "$INSTALL_TO"


exit 0
#
#EOF
