#!/usr/bin/env zsh -f
# Purpose: Download and install Hazel 5
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2020-11-18

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

	# MIN_VERSION=$(echo "$INFO" \
	# 			| fgrep '<sparkle:minimumSystemVersion>' \
	# 			| sed 	-e 's#.*<sparkle:minimumSystemVersion>##g' \
	# 					-e 's#</sparkle:minimumSystemVersion>##g')
MIN_VERSION='10.13'

OS_VER=$(sw_vers -productVersion)

autoload is-at-least

is-at-least "$MIN_VERSION" "$OS_VER"

EXIT="$?"

if [[ "$EXIT" != "0" ]]
then
	echo "$NAME: Hazel 5 requires at least '$MIN_VERSION' and you're running '$OS_VER'." >>/dev/stderr
	echo "$NAME: try 'di-hazel4.sh' instead. You can find it at:" >>/dev/stderr
	echo "https://github.com/tjluoma/di/blob/master/di-hazel4.sh" >>/dev/stderr
	exit 2
fi

INSTALL_TO='/Applications/Hazel.app'

	## 2021-01-23 this now redirects to the .php URL below
	# XML_FEED='https://www.noodlesoft.com/Products/Hazel/appcast'

XML_FEED='https://www.noodlesoft.com/Products/Hazel/generate-appcast.php'

INFO=$(curl -sfLS "$XML_FEED" | awk '/<item>/{i++}i==1')

RELEASE_NOTES_URL=$(echo "$INFO" | awk -F'>|<' '/description/{print $3}')

LATEST_VERSION=$(echo "$INFO" | tr ' ' '\012' | awk -F'"' '/^sparkle:version=/{print $2}')

	## 2021-01-23 - this is how I had been doing it previously, but trying new way
	# URL=$(curl --head -sfLS "https://www.noodlesoft.com/Products/Hazel/download" | awk -F' |\r' '/^Location: /{print $2}')
URL="https://s3.amazonaws.com/Noodlesoft/Hazel-${LATEST_VERSION}.dmg"

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleShortVersionString)

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	VERSION_COMPARE="$?"

	if [ "$VERSION_COMPARE" = "0" ]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION)"
		exit 0
	fi

	echo "$NAME: Outdated: $INSTALLED_VERSION vs $LATEST_VERSION"

	FIRST_INSTALL='no'

	if [[ ! -w "$INSTALL_TO" ]]
	then
		echo "$NAME: '$INSTALL_TO' exists, but you do not have 'write' access to it, therefore you cannot update it." >>/dev/stderr

		exit 2
	fi

else

	FIRST_INSTALL='yes'
fi

FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${${LATEST_VERSION}// /}.dmg"

RELEASE_NOTES_TXT="$FILENAME:r.txt"

if [[ -e "$RELEASE_NOTES_TXT" ]]
then

	cat "$RELEASE_NOTES_TXT"

else

	if (( $+commands[lynx] ))
	then

		RELEASE_NOTES=$(curl -sfLS "$RELEASE_NOTES_URL" | lynx -assume_charset=UTF-8 -stdin -pseudo_inlines -dump -nomargins -width=10000)

		echo "${RELEASE_NOTES}\n\nSource: ${RELEASE_NOTES_URL}\nVersion : ${LATEST_VERSION}\nURL: $URL" | tee "$RELEASE_NOTES_TXT"

	fi

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

egrep -q '^Local sha256:$' "$FILENAME:r.txt" 2>/dev/null

EXIT="$?"

if [ "$EXIT" = "1" -o ! -e "$FILENAME:r.txt" ]
then
	(cd "$FILENAME:h" ; \
		echo "\n\nLocal sha256:" ; \
		shasum -a 256 "$FILENAME:t" \
	)  >>| "$FILENAME:r.txt"
fi

echo "$NAME: Accepting license and Mounting $FILENAME:"

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
	echo "$NAME: moving old installed version to '$HOME/.Trash'..."
	mv -f "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.${INSTALLED_VERSION}_${INSTALLED_BUILD}.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then

		echo "$NAME: failed to move '$INSTALL_TO' to '$HOME/.Trash'. ('mv' \$EXIT = $EXIT)"

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
