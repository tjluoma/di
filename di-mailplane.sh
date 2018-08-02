#!/bin/zsh -f
# Purpose: Download and install Mailplane.app (v3)
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2015-02-02

NAME="$0:t:r"

INSTALL_TO='/Applications/Mailplane 3.app'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

# This is a new URL, to keep in case it's needed in the future
# XML_FEED="https://rink.hockeyapp.net/api/2/apps/e5d0b87b6eecc18e40fcd29f2125ac7d"


## 2018-07-17 - this is the URL I was using

# OS_VER=`sw_vers -productVersion`
#
# INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleVersion 2>/dev/null || echo '0'`
#
# XML_FEED="https://update.mailplaneapp.com/appcast.php?appName=Mailplane%203&osVersion=${OS_VER}&appVersion=${INSTALLED_VERSION}&selectedLanguage=en"
#
# INFO=($(curl -sfL "$XML_FEED" \
# 		| gunzip \
# 		| tr -s ' ' '\012' \
# 		| egrep 'sparkle:version=|url=' \
# 		| head -2 \
# 		| sort \
# 		| awk -F'"' '/^/{print $2}' ))
#
# 	# "Sparkle" will always come before "url" because of "sort"
# LATEST_VERSION="$INFO[1]"
#
# URL="$INFO[2]"
#
#
# 	# If any of these are blank, we should not continue
# if [ "$INFO" = "" -o "$LATEST_VERSION" = "" -o "$URL" = "" ]
# then
# 	echo "$NAME: Error: bad data received:
# 	INFO: $INFO
# 	LATEST_VERSION: $LATEST_VERSION
# 	URL: $URL
# 	"
#
# 	exit 1
# fi

URL=$(curl -sfL --head http://update.mailplaneapp.com/mailplane_3.php | awk -F': ' '/^Location/{print $NF}' | tail -1 | tr -d '[:cntrl:]')

[[ "$URL" == "" ]] && echo "$NAME: Empty URL" && exit 1

LATEST_VERSION=`echo "$URL:t:r" | sed 's#Mailplane_3_##g'`

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleVersion 2>/dev/null || echo '0'`

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

FILENAME="$HOME/Downloads/MailPlane-3-${LATEST_VERSION}.tbz"

echo "$NAME: Downloading $URL to $FILENAME"

 curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download failed (EXIT = $EXIT)" && exit 0


if [[ -e "$INSTALL_TO" ]]
then
		# Quit app, if running
	pgrep -xq "MailPlane 3" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "MailPlane 3" to quit'

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/MailPlane 3.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h"

tar -x -C "$INSTALL_TO:h" -j -f "$FILENAME"

EXIT="$?"

if [[ "$EXIT" == "0" ]]
then
	echo "$NAME: Installation of $INSTALL_TO was successful."
	exit 0
else
	echo "$NAME: Installation of $INSTALL_TO failed (\$EXIT = $EXIT)\nThe downloaded file can be found at $FILENAME."
	exit 1
fi

exit 0
#
#EOF
