#!/bin/zsh
# Purpose:
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


INFO=($(curl -sfL 'http://subtitlesapp.com/updates.xml' \
| fgrep '<enclosure ' \
| head -1 ))

DOWNLOAD_URL=`echo "$INFO[2]" | sed 's#url="##g ; s#"##g'`

LATEST_VERSION=`echo "$INFO[3]" | sed 's#sparkle:version="##g ; s#"##g'`

INSTALLED_VERSION=`defaults read /Applications/Subtitles.app/Contents/Info CFBundleShortVersionString 2>/dev/null`

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

FILENAME="$PWD/$DOWNLOAD_URL:t"

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

if [[ -e "/Applications/Subtitles.app" ]]
then
	mv -f /Applications/Subtitles.app "$HOME/.Trash/Subtitles.$INSTALLED_VERSION.app"
fi

ditto --noqtn -xk "$FILENAME:t" /Applications

exit 0
#
#EOF
