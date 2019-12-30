#!/bin/zsh -f
# Purpose: Download and install the latest version of TaskPaper
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-18

NAME="$0:t:r"

	# This is where the app will be installed or updated.
if [[ -d '/Volumes/Applications' ]]
then
	INSTALL_TO='/Volumes/Applications/TaskPaper.app'
else
	INSTALL_TO='/Applications/TaskPaper.app'
fi

HOMEPAGE="https://www.taskpaper.com"

DOWNLOAD_PAGE="https://www.taskpaper.com/assets/app/TaskPaper.dmg"

SUMMARY="Plain text to-do lists for Mac"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

	# via Cask folks
XML_FEED='https://www.taskpaper.com/assets/app/TaskPaper.rss'

INFO=($(curl -sfL "$XML_FEED" \
	| tr -s ' ' '\012' \
	| egrep 'sparkle:version=|sparkle:shortVersionString=|url=' \
	| head -3 \
	| sort \
	| awk -F'"' '/^/{print $2}'))

	# "Sparkle" will always come before "url" because of "sort"
LATEST_VERSION="$INFO[1]"
LATEST_BUILD="$INFO[2]"
URL="$INFO[3]"

	# If any of these are blank, we should not continue
if [ "$INFO" = "" -o "$LATEST_BUILD" = "" -o "$URL" = "" -o "$LATEST_VERSION" = "" ]
then
	echo "$NAME: Error: bad data received:
	INFO: $INFO
	LATEST_VERSION: $LATEST_VERSION
	LATEST_BUILD: $LATEST_BUILD
	URL: $URL
	"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleShortVersionString)

	INSTALLED_BUILD=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleVersion)

	autoload is-at-least

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	VERSION_COMPARE="$?"

	is-at-least "$LATEST_BUILD" "$INSTALLED_BUILD"

	BUILD_COMPARE="$?"

	if [ "$VERSION_COMPARE" = "0" -a "$BUILD_COMPARE" = "0" ]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION/$INSTALLED_BUILD)"
		exit 0
	fi

	echo "$NAME: Outdated: $INSTALLED_VERSION/$INSTALLED_BUILD vs $LATEST_VERSION/$LATEST_BUILD"

	FIRST_INSTALL='no'

	if [[ -e "$INSTALL_TO/Contents/_MASReceipt/receipt" ]]
	then
		echo "$NAME: $INSTALL_TO was installed from the Mac App Store and cannot be updated by this script."
		echo "	See <https://apps.apple.com/us/app/taskpaper-plain-text-to-dos/id1090940630?mt=12> or"
		echo "	<macappstore://apps.apple.com/us/app/taskpaper-plain-text-to-dos/id1090940630>"
		echo "	Please use the App Store app to update it: <macappstore://showUpdatesPage?scan=true>"
		exit 0
	fi

else

	FIRST_INSTALL='yes'
fi

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}_${LATEST_BUILD}.dmg"

if (( $+commands[lynx] ))
then

	RELEASE_NOTES_URL="$XML_FEED"

	( echo "$NAME: Release Notes for $INSTALL_TO:t:r\n" ;
	curl -sfl "$RELEASE_NOTES_URL" \
	| sed '1,/<item>/d; /<sparkle:version>/,$d' \
	| sed 's#\<\!\[CDATA\[##g ; s#\]\]\>##g' \
	| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin \
	| tr -s '_' '_' ;
	echo "\nSource: XML_FEED <${RELEASE_NOTES_URL}>" ) | tee "$FILENAME:r.txt"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
		| fgrep -A 1 '<key>mount-point</key>' \
		| tail -1 \
		| sed 's#</string>.*##g ; s#.*<string>##g')

if [[ "$MNTPNT" == "" ]]
then
	echo "$NAME: MNTPNT is empty"
	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then
		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/TaskPaper.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $MNTPNT/TaskPaper.app to $INSTALL_TO"

ditto --noqtn -v "$MNTPNT/TaskPaper.app" "$INSTALL_TO"

EXIT="$?"

if [ "$EXIT" = "0" ]
then

	echo "$NAME: Installation/Update successful"

else
	echo "$NAME: failed (\$EXIT = $EXIT)"

	exit 1
fi

diskutil eject "$MNTPNT"

exit 0
#EOF
