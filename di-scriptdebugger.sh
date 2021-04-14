#!/usr/bin/env zsh -f
# Purpose: Download and install the latest version of Script Debugger
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-08-03

NAME="$0:t:r"

INSTALL_TO='/Applications/Script Debugger.app'

HOMEPAGE="http://latenightsw.com/"

DOWNLOAD_PAGE="http://latenightsw.com/sd7/download/"

SUMMARY="You want your computer systems to be simple, reliable and automatic. Script Debugger is the integrated development environment that makes that happen by making your AppleScript coding easier, faster, and more transparent. And now, for the first time, it is available in a free “lite” mode that offers you a taste of the full power of Script Debugger."

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

XML_FEED='https://www.latenightsw.com/versions/com.latenightsw.ScriptDebugger7.php'

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
if [ "$INFO" = "" -o "$LATEST_VERSION" = "" -o "$LATEST_BUILD" = "" -o "$URL" = "" ]
then
	echo "$NAME: Error: bad data received:\nINFO: $INFO\nLATEST_VERSION: $LATEST_VERSION\nLATEST_BUILD: $LATEST_BUILD\nURL: $URL"
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

else

	FIRST_INSTALL='yes'
fi

FILENAME="$HOME/Downloads/ScriptDebugger-${LATEST_VERSION}_${LATEST_BUILD}.dmg"

if (( $+commands[lynx] ))
then

	echo "$NAME: Release Notes for $INSTALL_TO:t:r version $LATEST_VERSION/$LATEST_BUILD:\n"

	RELEASE_NOTES_URL="$XML_FEED"

	( curl -sfL "${RELEASE_NOTES_URL}" | sed '1,/<\/style>/d; /<h2 id="toc_1">/,$d' \
	| sed '1,/<\/style>/d'  \
	| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin \
	| egrep -v 'FIXED NEW UPDATE' \
	| uniq ;
	echo "\nSource: XML_FEED: <$RELEASE_NOTES_URL>" ) | tee "$FILENAME:r.txt"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

echo "$NAME: Accepting EULA and mounting $FILENAME (sorry if this opens a Finder window):"

MNTPNT=$(echo -n "Y" \
	| hdid -plist "$FILENAME" 2>/dev/null \
	| fgrep '/Volumes/' \
	| sed 's#</string>##g ; s#.*<string>##g')

if [[ "$MNTPNT" == "" ]]
then
	echo "$NAME: MNTPNT is empty"
	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then
		# Quit app, if running
	pgrep -xq "$INSTALL_TO:t:r" \
	&& LAUNCH='yes' \
	&& osascript -e "tell application \"$INSTALL_TO:t:r\" to quit"

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing '$MNTPNT/$INSTALL_TO:t' to '$INSTALL_TO': "

ditto --noqtn -v "$MNTPNT/$INSTALL_TO:t" "$INSTALL_TO"

EXIT="$?"

if [[ "$EXIT" == "0" ]]
then
	echo "$NAME: Successfully installed $INSTALL_TO"
else
	echo "$NAME: ditto failed"

	exit 1
fi

echo "$NAME: Unmounting $MNTPNT:"

diskutil eject "$MNTPNT"

[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"

exit 0
#EOF
