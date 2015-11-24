#!/bin/zsh -f
# 
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-10

NAME="$0:t:r"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

# curl -sfL http://versioncheck.busymac.com/busycal/news.plist

URL='http://www.busymac.com/download/BusyCal.zip'

LATEST_VERSION=`curl -sfL http://versioncheck.busymac.com/busycal/news.plist| fgrep -A1 '<key>current</key>' | fgrep '<string>' | head -1 | tr -dc '[0-9].'`

INSTALL_TO='/Applications/BusyCal.app'

INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo '2.0.0'`

autoload is-at-least

is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

if [ "$?" = "0" ]
then
	echo "$NAME: Up-To-Date (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"
	exit 0
fi

echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"

FILENAME="$HOME/Downloads/BusyCal-$LATEST_VERSION.zip"
	PKG="$FILENAME:h/BusyCal-$LATEST_VERSION.pkg"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

cd "$FILENAME:h"

ditto -xk -v --rsrc --extattr "$FILENAME" . \
&& mv -f "$FILENAME" "$HOME/.Trash/"


mv -vf "BusyCal Installer.pkg" "$PKG"

if (( $+commands[pkginstall.sh] ))
then

	pkginstall.sh "$PKG"

else

	sudo installer -pkg "$PKG" -target / -lang en 2>&1

fi





# 
# if [ -e "$INSTALL_TO" ]
# then
# 		# Quit app, if running
# 	pgrep -xq "BusyCal" \
# 	&& LAUNCH='yes' \
# 	&& osascript -e 'tell application "BusyCal" to quit'
# 
# 		# move installed version to trash 
# 	mv -vf "$INSTALL_TO" "$HOME/.Trash/BusyCal.$INSTALLED_VERSION.app"
# 
# 	EXIT="$?"
# 
# 	if [ "$EXIT" = "1" ]
# 	then
# 		if (( $+commands[trash] ))
# 		then
# 
# 			trash "$INSTALL_TO"
# 		else
# 			sudo mv -v "$INSTALL_TO" "$HOME/.Trash/BusyCal.$INSTALLED_VERSION.app" 	
# 
# 		fi
# 
# 	fi
# 	
# 	
# fi




exit 0
#
#EOF
