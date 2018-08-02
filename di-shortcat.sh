#!/bin/zsh -f
# Purpose: Download and install the latest version of Shortcat
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2015-06-01

NAME="$0:t:r"

INSTALL_TO='/Applications/Shortcat.app'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

	# 2018-07-17 - alt feed:
	# https://rink.hockeyapp.net/api/2/apps/df3146d3d4af7a00d9f298d67a1e93a9
XML_FEED='https://shortcatapp.com/updates/appcast.xml'

# sparkle:version and shortVersionString are both in the feed, but only shortVersionString seems to matter

INFO=($(curl -sfL "$XML_FEED" \
		| tr -s ' ' '\012' \
		| egrep '(url=|sparkle:shortVersionString=)' \
		| head -2 \
		| awk -F'"' '//{print $2}'))

URL_RAW=`echo "$INFO[1]" | sed 's#&amp\;#\&#g' `

	# 2018-07-10 - changed Location to location (case change)
URL=`curl -sfL --head "$URL_RAW" | awk -F' ' '/^location:/{print $NF}' | tr -d '\r' `

LATEST_VERSION="$INFO[2]"

if [ "$INFO" = "" -o "$LATEST_VERSION" = "" -o "$URL" = "" ]
then
	echo "$NAME: Bad data from $XML_FEED
	INFO: $INFO
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString`

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

if [[ "$EXIT" == "0" ]]
then
	echo "$NAME: Installation of $INSTALL_TO was successful."
	exit 0
else
	echo "$NAME: Installation of $INSTALL_TO failed (\$EXIT = $EXIT)\nThe downloaded file can be found at $FILENAME."
	exit 1
fi

[[ "$LAUNCH" == "yes" ]] && open -a Shortcat

exit 0

#
#EOF
