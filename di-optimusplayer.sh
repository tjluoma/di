#!/usr/bin/env zsh -f
# Purpose: Download and install/update the latest version of Optimus Player
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2019-10-16

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

INSTALL_TO='/Applications/Optimus Player.app'

XML_FEED='https://download.optimusplayer.com/appcast.xml'

INFO=$(curl -sfLS "$XML_FEED" \
| sed 's#^[ 	]*##g' \
| tr -d '\012' \
| sed -e 's#</channel></rss>##g' \
-e 's#<item>#\
<item>#g' \
| egrep '^<item>' \
| tail -1 \
| sed -e 's#><#>\
<#g' \
-e 's#<\!\[CDATA\[##g' \
-e 's#\]\]>##g' \
| egrep -iv 'sparkle:deltas|\.delta')

LATEST_VERSION=$(echo "$INFO" | awk -F'"' '/sparkle:version/{print $6}')

LATEST_BUILD=$(echo "$INFO" | awk -F'"' '/sparkle:version/{print $4}')

URL=$(echo "$INFO" | awk -F'"' '/sparkle:version/{print $2}')

	# If any of these are blank, we cannot continue
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

fi

FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${LATEST_VERSION}_${LATEST_BUILD}.dmg"

if (( $+commands[lynx] ))
then

	RELEASE_NOTES=$(echo "$INFO" \
			| sed '1,/<description>/d; /<\/description>/,$d' \
			| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin)

	( echo "${RELEASE_NOTES}\n\nURL: $URL" ) | tee "$FILENAME:r.txt"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

(cd "$FILENAME:h" ; echo "\nLocal sha256:" ; shasum -a 256 "$FILENAME:t" ) >>| "$FILENAME:r.txt"

echo "$NAME: accepting EULA and mounting '$FILENAME'. Sorry if this opens a Finder window. It’s not my fault!"

MNTPNT=$(echo -n "Y" | hdid -plist "$FILENAME" 2>/dev/null | fgrep '/Volumes/' | sed 's#</string>##g ; s#.*<string>##g')

if [[ "$MNTPNT" == "" ]]
then
	echo "$NAME: MNTPNT is empty"
	exit 1
else
	echo "$NAME: MNTPNT is $MNTPNT"
fi

if [[ -e "$INSTALL_TO" ]]
then
		# Quit app, if running
	pgrep -xq "$INSTALL_TO:t:r" \
	&& LAUNCH='yes' \
	&& osascript -e "tell application \"$INSTALL_TO:t:r\" to quit"

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.${INSTALLED_VERSION}_${INSTALLED_BUILD}.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then

		echo "$NAME: failed to move '$INSTALL_TO' to Trash. ('mv' \$EXIT = $EXIT)"

		exit 1
	fi

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

[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"

echo -n "$NAME: Unmounting $MNTPNT: " && diskutil eject "$MNTPNT"

exit 0
#EOF
