#!/bin/zsh -f
# Purpose:
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2015-10-23

NAME="$0:t:r"

DIR="$HOME/Downloads"


if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

LOCAL_INSTALL="$HOME/Library/PreferencePanes/Hazel.prefPane"

SYSTEM_INSTALL='/Library/PreferencePanes/Hazel.prefPane'

if [ -e "$SYSTEM_INSTALL" -a -e "$LOCAL_INSTALL" ]
then
	echo "$NAME: Hazel is installed at BOTH $LOCAL_INSTALL and $SYSTEM_INSTALL. Please remove one."
	exit 1
elif [ -e "$SYSTEM_INSTALL" ]
then
	INSTALL_TO="$SYSTEM_INSTALL"
elif [ -e "$LOCAL_INSTALL" ]
then
	INSTALL_TO="$LOCAL_INSTALL"
else
	INSTALL_TO="$LOCAL_INSTALL"
fi

	# If there's no installed version, output 3.0.0 so the Sparkle feed will give us the proper download URL
INSTALLED_VERSION=`defaults read ${INSTALL_TO}/Contents/Info CFBundleShortVersionString 2>/dev/null || echo '3.0.0'`


INFO=($(curl -sfL "http://update.noodlesoft.com/Products/Hazel/appcast.php?version=$INSTALLED_VERSION" \
			| tr -s ' ' '\012' \
			| egrep '^(sparkle:version|url)=' \
			| head -2 \
			| awk -F'"' '/=/{print $2}'))

LATEST_VERSION="$INFO[1]"

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

URL="$INFO[2]"

FILENAME="$DIR/Hazel-$LATEST_VERSION.dmg"

echo "$NAME: Downloading $URL to $FILENAME"
curl --continue-at - -fL --progress-bar --output "$FILENAME" "$URL"


MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
		| fgrep -A 1 '<key>mount-point</key>' \
		| tail -1 \
		| sed 's#</string>.*##g ; s#.*<string>##g')

if [[ "$MNTPNT" == "" ]]
then
		msg --die "Failed to mount $FILENAME. (MNTPNT is empty)"
		exit 1
fi

# If we get here we are ready to install

# Quit HazelHelper
pkill HazelHelper

if [ -e "$INSTALL_TO" ]
then
	mv -vf "$INSTALL_TO" "$HOME/.Trash/Hazel.$INSTALLED_VERSION.prefPane"
fi

echo "$NAME: Installing $MNTPNT/Hazel.prefPane to $INSTALL_TO.."
ditto --noqtn -v "$MNTPNT/Hazel.prefPane" "$INSTALL_TO"


EXIT="$?"

if [ "$EXIT" = "0" ]
then
	unmount.sh "$MNTPNT" &|

else
	MSG="Hazel installation failed (\$EXIT = $EXIT)"

	po.sh "$MSG"

	echo "$NAME: $MSG"

	exit 0
fi


echo "$NAME: Launching HazelHelper..."

growlnotify  \
	--appIcon "HazelHelper" \
	--identifier "$NAME" \
	--message "Launching Hazel Helper" \
	--title "$NAME" 2>/dev/null


open --background -a "$INSTALL_TO/Contents/MacOS/HazelHelper.app"


if [[ ! -e "$HOME/Library/Application Support/Hazel/license" ]]
then

	LICENSE="$HOME/dotfiles/licenses/hazel/Hazel-3.hazellicense"

	if [[ -e "$LICENSE" ]]
	then
		open "$LICENSE" || open -R "$LICENSE"
	else
		MSG="Hazel is unlicensed and no Hazel-3.hazellicense found at $LICENSE"

		echo "$NAME: $MSG"

		growlnotify  \
			--appIcon "HazelHelper" \
			--identifier "$NAME" \
			--message "$MSG" \
			--title "$NAME" 2>/dev/null
	fi
fi

exit 0
#
#EOF
