#!/bin/zsh -f
# Purpose: 
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-18

NAME="$0:t:r"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

INSTALL_TO='/Applications/TaskPaper.app'

INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo '150'`

XML_FEED='https://taskpaper.s3.amazonaws.com/TaskPaper.rss'

INFO=($(curl -sfL "$XML_FEED" \
| tr -s ' ' '\012' \
| egrep 'sparkle:shortVersionString=|url=' \
| head -2 \
| sort \
| awk -F'"' '/^/{print $2}'))

	# "Sparkle" will always come before "url" because of "sort"
LATEST_VERSION="$INFO[1]"
URL="$INFO[2]"

	# If any of these are blank, we should not continue
if [ "$INFO" = "" -o "$LATEST_VERSION" = "" -o "$URL" = "" ]
then
	echo "$NAME: Error: bad data received:\nINFO: $INFO"
	exit 0
fi

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

FILENAME="$HOME/Downloads/TaskPaper3-Preview-$LATEST_VERSION.dmg"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
		| fgrep -A 1 '<key>mount-point</key>' \
		| tail -1 \
		| sed 's#</string>.*##g ; s#.*<string>##g')

if [[ "$MNTPNT" == "" ]]
then
	echo "$NAME: MNTPNT is empty"
	exit 1
fi

if [ -e "$INSTALL_TO" ]
then
		# Quit app, if running
	pgrep -xq "TaskPaper" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "TaskPaper" to quit'

		# move installed version to trash 
	mv -vf "$INSTALL_TO" "$HOME/.Trash/TaskPaper.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $MNTPNT/TaskPaper.app to $INSTALL_TO"

ditto -v "$MNTPNT/TaskPaper.app" "$INSTALL_TO" \
&& diskutil eject "$MNTPNT" \
&& rm -f "$FILENAME"
## These are betas and they are coming out very often, so there's no need to keep them


exit 0
#EOF
