#!/bin/zsh -f
# Purpose: Download and install latest version of Subtitlesapp.com
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2015-05-01

NAME="$0:t:r"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

INSTALL_TO='/Applications/Subtitles.app'

INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo 3`

	# XML file is... unusual.
INFO=($(curl -sfL 'http://subtitlesapp.com/updates.xml' \
| tidy --input-xml yes --output-xml yes --show-warnings no --force-output yes --quiet yes --wrap 0 \
| sed 's#&lt;#<#g ; s#&gt;#>#g ' \
| fgrep 'sparkle:version=' \
| head -1 \
| tr -s ' ' '\012' \
| sort \
| egrep 'sparkle:version=|url=' \
| awk -F'"' '/^/{print $2}'))

	# "Sparkle" will always come before "url" because of "sort"
LATEST_VERSION="$INFO[1]"
URL="$INFO[2]"

	# If any of these are blank, we should not continue
if [ "$INFO" = "" -o "$LATEST_VERSION" = "" -o "$URL" = "" ]
then
		echo 

	URL=`curl -sfL --head 'http://subtitlesapp.com/download/' | awk -F' ' '/^Location:/{print $2}' | tail -1 | tr -d '\r'`

	LATEST_VERSION=`echo "$URL:t:r" | tr -dc '[0-9].'`

fi

autoload is-at-least

is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

if [ "$?" = "0" ]
then
	echo "$NAME: Up-To-Date (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"
	exit 0
fi

echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"


STATUS=`curl -sfL --head "$URL" | awk -F' ' '/^HTTP/{print $2}'`

if [[ "$STATUS" != "200" ]]
then
	echo "$NAME: Bad HTTP Status for $URL ($STATUS != 200)"
	exit 0
fi 

cd '/Volumes/Data/Websites/iusethis.luo.ma/subtitles/' 2>/dev/null \
	|| cd "$HOME/BitTorrent Sync/iusethis.luo.ma/subtitles/" 2>/dev/null \
	|| cd "$HOME/Downloads/" 2>/dev/null \
	|| cd "$HOME/Desktop/" 2>/dev/null \
	|| cd "$HOME/"

FILENAME="$PWD/Subtitles-$LATEST_VERSION.zip"

if [[ -e "$FILENAME" ]]
then
	echo "$URL"
	curl --continue-at - --fail --location --progress-bar --output "$FILENAME" "$URL"

else
	# if filename does not exist in CWD

	if [[ -d "old" ]]
	then
			# move files to 'old' dir, if exists
		mv -vf *.zip old/ 2>/dev/null || true
	fi

	echo "$URL"
	curl -fL --progress-bar --output "$FILENAME" "$URL"
fi


# if running, quit
pgrep -xq Subtitles \
&& osascript -e 'tell application "Subtitles" to quit'

if [[ -e "$INSTALL_TO" ]]
then
	mv -f "$INSTALL_TO" "$HOME/.Trash/Subtitles.$INSTALLED_VERSION.app"
fi

ditto --noqtn -xk "$FILENAME:t" "$INSTALL_TO:h"

exit 0
#
#EOF
