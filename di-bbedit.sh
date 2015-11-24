#!/bin/zsh -f
# Purpose:
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-10-28

NAME="$0:t:r"

if [ -e "/Users/luomat/.path" ]
then
	source "/Users/luomat/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

INFO=($(curl -sfL 'https://versioncheck.barebones.com/BBEdit.cgi' \
| egrep -A1 '<key>SUFeedEntryShortVersionString</key>|<key>SUFeedEntryUpdateURL</key>' \
| fgrep '<string>' \
| tail -2 \
| sed 's#.*<string>##g; s#</string>.*##g'))

LATEST_VERSION="$INFO[1]"

URL="$INFO[2]"

INSTALL_TO='/Applications/BBEdit.app'

INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo '11.0.0'`

autoload is-at-least

is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

if [ "$?" = "0" ]
then
	echo "$NAME: Up-To-Date (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"
	exit 0
fi

echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"

FILENAME="$HOME/Downloads/BBEdit-$LATEST_VERSION.zip"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

if [ -e "$INSTALL_TO" ]
then
		# Quit app, if running
	pgrep -xq "BBEdit" && pkill "BBEdit"

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/BBEdit.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

ditto --noqtn -xk "$FILENAME" "$INSTALL_TO:h/"




exit 0
#EOF
