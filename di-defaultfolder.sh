#!/bin/zsh -f
# Purpose:
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-05

NAME="$0:t:r"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

# XML_FEED='http://www.stclairsoft.com/updates/DefaultFolderX5.XML_FEED'

XML_FEED='https://www.stclairsoft.com/cgi-bin/sparkle.cgi?DX5'

INSTALL_TO="/Applications/Default Folder X.app"

# User Agent = Default Folder X/5.0b1 Sparkle/58

INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo '0'`

SHORT_VER=`defaults read "$INSTALL_TO/Contents/Info" CFBundleVersion 2>/dev/null || echo '0'`

UA="Default Folder X/$INSTALLED_VERSION Sparkle/$SHORT_VER"

INFO=($(curl -sfL -A "$UA" "$XML_FEED" \
		| tr -s ' ' '\012' \
		| egrep '^(sparkle:shortVersionString|url)=' \
		| head -2 \
		| awk -F'"' '//{print $2}'))

LATEST_VERSION="$INFO[2]"

URL="$INFO[1]"

if [[ "$LATEST_VERSION" == "$SHORT_VER" ]]
then
	echo "$NAME: Up-To-Date (Installed/Latest Version = $INSTALLED_VERSION)"
	exit 0
fi

if [[ "$INSTALLED_VERSION" = "$LATEST_VERSION" ]]
then
	echo "$NAME: Up-To-Date ($INSTALLED_VERSION)"
	exit 0 
fi 

autoload is-at-least

is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"
 
if [ "$?" = "0" ]
then
	echo "$NAME: Installed version  ($INSTALLED_VERSION) is ahead of official version $LATEST_VERSION"
	exit 0
fi

echo "$NAME: Outdated (Installed = $SHORT_VER vs Latest = $LATEST_VERSION)"

RSIZE=`curl -sfL --head "$URL" | awk -F' ' '/Content-Length/{print $NF}' | tr -d '\r'`

FILENAME="$HOME/Downloads/DefaultFolderX-$LATEST_VERSION.dmg"

echo "$NAME: Downloading $URL to $FILENAME"

if [ -e "$FILENAME" ]
then

	zmodload zsh/stat

	SIZE=$(zstat -L +size "$FILENAME")

	while [ "`zstat -L +size ${FILENAME}`" -lt "$RSIZE" ]
	do
		curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"
	done

else

	curl --progress-bar --fail --location --output "$FILENAME" "$URL" || exec 0
fi


if [ -e "$INSTALL_TO" ]
then
		# Quit app, if running
	pgrep -xq "Default Folder X" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "Default Folder X" to quit'

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/Default Folder X.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
		| fgrep -A 1 '<key>mount-point</key>' \
		| tail -1 \
		| sed 's#</string>.*##g ; s#.*<string>##g')


if [[ "$MNTPNT" == "" ]]
then
		echo "$NAME: failed to mount $FILENAME. (MNTPNT is empty)"
		exit 1
fi

ditto --noqtn "$MNTPNT/$INSTALL_TO:t" "$INSTALL_TO"

diskutil eject "$MNTPNT"


[[ "$LAUNCH" = "yes" ]] && open --background -a "$INSTALL_TO"


if (is-growl-running-and-unpaused.sh)
then

	growlnotify  \
	--appIcon "Default Folder X" \
	--identifier "$NAME" \
	--message "Updated to $LATEST_VERSION" \
	--title "$NAME"

fi



exit 0
#EOF
