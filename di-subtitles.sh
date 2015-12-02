#!/bin/zsh -f
# Purpose:
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2015-05-01

## 2015-12-02 - Because the XML file is out of date, I'm actually checking to see where 'http://subtitlesapp.com/download/' redirects
## 				and stripping the URL down to the version number 

NAME="$0:t:r"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

URL=`curl -sfL --head 'http://subtitlesapp.com/download/' | awk -F' ' '/^Location:/{print $2}' | tail -1 | tr -d '\r'`

if [[ "$URL" == "" ]] 
then
			# 2015-12-02 the XML file is out of date 

	LATEST_VERSION=`curl -sfL 'http://subtitlesapp.com/updates.xml' \
		| tidy --input-xml yes --output-xml yes --show-warnings no --force-output yes --quiet yes --wrap 0 \
		| sed 's#&lt;#<#g ; s#&gt;#>#g' \
		| fgrep '<title>' \
		| head -1 \
		| tr -dc '[0-9].'`

	URL="http://subtitlesapp.com/download/Subtitles-mac-$LATEST_VERSION.zip"

else
	LATEST_VERSION=`echo "$URL:t:r" | tr -dc '[0-9].'`
fi 

STATUS=`curl -sfL --head "$URL" | awk -F' ' '/^HTTP/{print $2}'`

if [[ "$STATUS" != "200" ]]
then
	echo "$NAME: Bad HTTP Status for $URL ($STATUS != 200)"
	exit 0
fi 

INSTALL_TO='/Applications/Subtitles.app'

INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null`

autoload is-at-least

is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

if [ "$?" = "0" ]
then
	echo "$NAME: Up-To-Date (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"
	exit 0
fi

echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"

cd '/Volumes/Data/Websites/iusethis.luo.ma/subtitles/' 2>/dev/null \
	|| cd "$HOME/BitTorrent Sync/iusethis.luo.ma/subtitles/" 2>/dev/null \
	|| cd "$HOME/Downloads/" 2>/dev/null \
	|| cd "$HOME/Desktop/" 2>/dev/null \
	|| cd "$HOME/"


FILENAME="$PWD/Subtitles-$LATEST_VERSION.zip"

if [[ -e "$FILENAME" ]]
then
	echo "$DOWNLOAD_URL"
	curl --continue-at - --fail --location --progress-bar --output "$FILENAME" "$DOWNLOAD_URL"

else
	# if filename does not exist in CWD

	if [[ -d "old" ]]
	then
			# move files to 'old' dir, if exists
		mv -vf *.zip old/ 2>/dev/null || true
	fi

	echo "$DOWNLOAD_URL"
	curl -fL --progress-bar --output "$FILENAME" "$DOWNLOAD_URL"
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
