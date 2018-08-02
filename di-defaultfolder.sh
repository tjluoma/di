#!/bin/zsh -f
# Purpose: Download and install the latest version of Default Folder X
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-05

NAME="$0:t:r"

INSTALL_TO='/Applications/Default Folder X.app'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

	# This is the URL actually given by the feed itself
	# 	XML_FEED='http://www.stclairsoft.com/updates/DefaultFolderX5.xml'
	# but this is the URL found in the app itself
XML_FEED='https://www.stclairsoft.com/cgi-bin/sparkle.cgi?DX5'

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString`

	INSTALLED_BUILD=`defaults read "$INSTALL_TO/Contents/Info" CFBundleVersion`

		# User Agent = Default Folder X/5.0b1 Sparkle/58
	UA="Default Folder X/$INSTALLED_VERSION Sparkle/$INSTALLED_BUILD"

else
		# This is current info as of 2018-08-02
	UA="Default Folder X/5.2.5 Sparkle/483"
fi

INFO=($(curl -sfL -A "$UA" "$XML_FEED" \
		 | tr -s ' ' '\012' \
		 | egrep '^(sparkle:shortVersionString|url|sparkle:version)=' \
		 | sort \
		 | head -3 \
		 | awk -F'"' '//{print $2}'))

## Expected output something like:
#
# 5.2.5
# 483
# https://www.stclairsoft.com/download/DefaultFolderX-5.2.5.dmg

LATEST_VERSION="$INFO[1]"
LATEST_BUILD="$INFO[2]"
URL="$INFO[3]"

if [ "$INFO" = "" -o "$LATEST_VERSION" = "" -o "$URL" = "" -o "$LATEST_BUILD" = "" ]
then
	echo "$NAME Error: bad data received:
	INFO: $INFO
	LATEST_VERSION: $LATEST_VERSION
	LATEST_BUILD: $LATEST_BUILD
	URL: $URL\n"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	if [[ "$INSTALLED_VERSION" = "$LATEST_VERSION" ]]
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

	echo "$NAME: Outdated (Installed = $INSTALLED_BUILD vs Latest = $LATEST_VERSION)"

fi

FILENAME="$HOME/Downloads/DefaultFolderX-${LATEST_VERSION}_${LATEST_BUILD}.dmg"

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

if [[ -e "$INSTALL_TO" ]]
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

echo "$NAME: Installing '$MNTPNT/$INSTALL_TO:t' to '$INSTALL_TO': "

ditto --noqtn -v "$MNTPNT/$INSTALL_TO:t" "$INSTALL_TO"

EXIT="$?"

if [[ "$EXIT" != "0" ]]
then
	echo "$NAME: ditto failed"

	exit 1
fi

echo "$NAME: Installation successful. Ejecting $MNTPNT:"

diskutil eject "$MNTPNT"

[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"

if (is-growl-running-and-unpaused.sh)
then
	growlnotify \
	--appIcon "Default Folder X" \
	--identifier "$NAME" \
	--message "Updated to $LATEST_VERSION" \
	--title "$NAME"
fi


exit 0
#EOF
