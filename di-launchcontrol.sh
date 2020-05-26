#!/usr/bin/env zsh -f
# Purpose: Download and install latest LaunchControl
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-05-26

NAME="$0:t:r"

INSTALL_TO='/Applications/LaunchControl.app'

HOMEPAGE="http://www.soma-zone.com/LaunchControl/"

DOWNLOAD_PAGE="http://www.soma-zone.com/download/"

SUMMARY="LaunchControlCreate, manage and debug launchd(8) services. LaunchControl is a fully-featured launchd GUI allowing you to create, manage and debug system- and user services on your Mac."

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

	##
	## 2019-06-11 - this one seems slightly slower to update, or is now out of date?
	## XML_FEED='https://somazonecom.ipage.com/soma-zone.com/LaunchControl/a/appcast_update.xml'
	##
	## This one is even older:
	## XML_FEED='http://www.soma-zone.com/LaunchControl/a/appcast_update.xml'

	# 2020-05-26 this is now 404
# XML_FEED='https://www.soma-zone.com/LaunchControl/a/appcast.xml'

	# 2020-05-26 this one is back
XML_FEED='http://www.soma-zone.com/LaunchControl/a/appcast_update.xml'

INFO=($(curl -sfL "$XML_FEED" \
		| tr '[:blank:]' '\012' \
		| egrep '^(url|sparkle:shortVersionString=)' \
		| tail -2 \
		| sort \
		| awk -F'"' '/^/{print $2}'))

LATEST_VERSION="$INFO[1]"

URL="$INFO[2]"

if [ "$URL" = "" -o "$LATEST_VERSION" = "" ]
then
	echo "$NAME: Bad data from $XML_FEED"
	echo "
	INFO: $INFO
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=`defaults read "${INSTALL_TO}/Contents/Info" CFBundleShortVersionString 2>/dev/null`

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

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-$LATEST_VERSION.tbz2"

if (( $+commands[lynx] ))
then

	RELEASE_NOTES_URL="$XML_FEED"

	(echo "$NAME: Release Notes for $INSTALL_TO:t:r version $LATEST_VERSION:" ;
	curl -sfL "$RELEASE_NOTES_URL" \
	| sed "1,/<title>Version $LATEST_VERSION<\/title>/d" \
	| sed '1,/<description>/d; /<\/description>/,$d' \
	| lynx -dump -nomargins -width=10000 -assume_charset=UTF-8 -pseudo_inlines -stdin ;
	echo "\nSource: XML_FEED: <$RELEASE_NOTES_URL>") | tee "$FILENAME:r.txt"

fi

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

if [[ -e "$INSTALL_TO" ]]
then
	mv -vn "$INSTALL_TO" "$HOME/.Trash/LaunchControl-$INSTALLED_VERSION.app"
fi

	# Unpack and Install the .tbz2 file to /Applications/

echo "$NAME: Installing $FILENAME to $INSTALL_TO..."

tar -C "/Applications/" -j -x -f "$FILENAME"

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
