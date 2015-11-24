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

URL='http://www.busymac.com/download/BusyContacts.zip'

LATEST_VERSION=`curl -sfL http://versioncheck.busymac.com/busycontacts/news.plist | fgrep -A1 '<key>current</key>' | fgrep '<string>' | head -1 | tr -dc '[0-9].'`

INSTALL_TO='/Applications/BusyContacts.app'

INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo '2.0.0'`

autoload is-at-least

is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

if [ "$?" = "0" ]
then
	echo "$NAME: Up-To-Date (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"
	exit 0
fi

echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"


FILENAME="$HOME/Downloads/BusyContacts-$LATEST_VERSION.zip"
	PKG="$FILENAME:h/BusyContacts-$LATEST_VERSION.pkg"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

cd "$FILENAME:h"

ditto -xk -v --rsrc --extattr "$FILENAME" . \
&& mv -f "$FILENAME" "$HOME/.Trash/"


mv -vf "BusyContacts Installer.pkg" "$PKG"

if (( $+commands[pkginstall.sh] ))
then

	pkginstall.sh "$PKG"

else

	sudo installer -pkg "$PKG" -target / -lang en 2>&1

fi


exit 0
#
#EOF
