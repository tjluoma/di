#!/usr/bin/env zsh -f
# Purpose: 	Download and install/update the latest version of MacPilot
#
# From:		Timothy J. Luoma
# Mail:		luomat at gmail dot com
# Date:		2021-09-18
# @TODO:	RELEASE_NOTES needs updating
# Verified:	2025-02-24

[[ -e "$HOME/.path" ]] && source "$HOME/.path"

[[ -e "$HOME/.config/di/defaults.sh" ]] && source "$HOME/.config/di/defaults.sh"

INSTALL_TO="${INSTALL_DIR_ALTERNATE-/Applications}/MacPilot.app"

NAME="$0:t:r"

OS_VER_MAJOR=$(sw_vers -productVersion | cut -d '.' -f 1)

if [[ "$OS_VER_MAJOR" -lt "11" ]]
then

	echo "$NAME: MacPilot 13 requires at least macOS version 11.
	You are using $(sw_vers -productVersion)." >>/dev/stderr

	exit 2
fi

	# The feed only has one entry in it
XML_FEED='https://www.koingosw.com/postback/versioncheck.php?appname=macpilot&type=sparkle'

LATEST_VERSION=$(curl -sfLS "$XML_FEED" | fgrep '<version>' | sed 's#</version##g ; s#.*<version>##g')

	# does not change
URL="https://www.koingosw.com/products/getmirrorfile.php?path=%2Fproducts%2Fmacpilot%2Fdownload%2Fmacpilot.dmg"

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleShortVersionString)

	autoload is-at-least

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

FILENAME="${DOWNLOAD_DIR_ALTERNATE-$HOME/Downloads}/${${INSTALL_TO:t:r}// /}-${${LATEST_VERSION}// /}.dmg"

RELEASE_NOTES_TXT="$FILENAME:r.txt"

if [[ -e "$RELEASE_NOTES_TXT" ]]
then

	cat "$RELEASE_NOTES_TXT"

else

	if (( $+commands[lynx] ))
	then

		alias mylynx='lynx -dump -nomargins -width="10000" -assume_charset=UTF-8 -pseudo_inlines -stdin'

		RELEASE_NOTES=$(curl -sfLS "$XML_FEED" \
						| awk '/<description>/{i++}i==2' \
						| tr -d '\012| ' \
						| sed 's#<description>##g ; s#</description>.*##g' \
						| mylynx \
						| mylynx \
						| sed G ; \
					echo "\nSource: <$XML_FEED>\n\nURL: ${URL}" )

		echo "${RELEASE_NOTES}\n\nSource: ${XML_FEED}\nVersion: ${LATEST_VERSION}\nURL: ${URL}" \
		| tee "$RELEASE_NOTES_TXT"

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

echo "$NAME: Mounting $FILENAME:"

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
		# Quit app, if running
	pgrep -xq "$INSTALL_TO:t:r" \
	&& LAUNCH='yes' \
	&& osascript -e "tell application \"$INSTALL_TO:t:r\" to quit"

		# move installed version to trash
	mv -f "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.${INSTALLED_VERSION}.app.$RANDOM"
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

echo "$NAME: Unmounting $MNTPNT:"

diskutil eject "$MNTPNT"

exit 0
#
#EOF
