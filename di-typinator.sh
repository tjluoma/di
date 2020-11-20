#!/usr/bin/env zsh -f
# Purpose:
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2020-02-23

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH="$HOME/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin"
fi

INSTALL_TO="/Applications/Typinator.app"

XML_FEED='https://update.ergonis.com/vck/typinator.xml'

RELEASE_NOTES_URL='https://www.ergonis.com/products/typinator/history.html'

# for version 8.3 the download URL is
# 	https://www.ergonis.com/downloads/products/typinator/Typinator83-Install.dmg
# but you can just use
#	https://www.ergonis.com/downloads/typinator-install.dmg
# as long as you fake your user-agent

URL="https://www.ergonis.com/downloads/typinator-install.dmg"

LATEST_VERSION=$(curl -A "Safari" -sfLS "$XML_FEED" | awk -F'>|<' '/Program_Version/{print $3}')

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

FILENAME="${DOWNLOAD_DIR-$HOME/Downloads}/${${INSTALL_TO:t:r}// /}-${${LATEST_VERSION}// /}.dmg"

RELEASE_NOTES="$FILENAME:r.txt"

if [[ -e "$RELEASE_NOTES" ]]
then

	cat "$RELEASE_NOTES"

elif (( $+commands[lynx] ))
then

	RELEASE_NOTES_TEXT=$(curl -A "Safari" -sfLS "$RELEASE_NOTES_URL" \
						| awk '/<h1>/{i++}i==1' \
						| lynx -dump -nomargins -width='10000' -display_charset=UTF-8 -assume_charset=UTF-8 -pseudo_inlines -stdin \
						| grep '.' \
						| sed -e 's#^    *##g' \
						| sed G)

	echo "${RELEASE_NOTES_TEXT}\n\nSource: ${RELEASE_NOTES_URL}\nVersion : ${LATEST_VERSION}\nURL: $URL" | tee "$RELEASE_NOTES"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl -A "Safari" --continue-at - --fail --location --output "${FILENAME}" "${URL}"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of '$URL' failed (EXIT = $EXIT)" >>/dev/stderr && exit 1

[[ ! -e "${FILENAME}" ]] && echo "$NAME: '${FILENAME}' does not exist." >>/dev/stderr && exit 1

[[ ! -s "${FILENAME}" ]] && echo "$NAME: '${FILENAME}' is zero bytes." >>/dev/stderr && rm -f "$FILENAME" && exit 1

egrep -q '^Local sha256:$' "$RELEASE_NOTES" 2>/dev/null

EXIT="$?"

if [ "$EXIT" = "1" -o ! -e "$RELEASE_NOTES" ]
then
	(cd "$FILENAME:h" ; \
	echo "\n\nLocal sha256:" ; \
	shasum -a 256 "$FILENAME:t" \
	)  >>| "$RELEASE_NOTES"
fi



# echo "$NAME: Accepting the EULA and mounting '${FILENAME}':"
#
# MNTPNT=$(echo -n "Y" | hdid -plist "$FILENAME" 2>/dev/null | fgrep '/Volumes/' | sed 's#</string>##g ; s#.*<string>##g')

echo "$NAME: Mounting '${FILENAME}':"

MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
	| fgrep -A 1 '<key>mount-point</key>' \
	| tail -1 \
	| sed 's#</string>.*##g ; s#.*<string>##g')

if [[ "$MNTPNT" == "" ]]
then
	echo "$NAME: MNTPNT is empty" >>/dev/stderr
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
	mv -f "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.${INSTALLED_VERSION}.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then

		echo "$NAME: failed to move '$INSTALL_TO' to '$HOME/.Trash'. ('mv' \$EXIT = $EXIT)" >>/dev/stderr

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
	echo "$NAME: ditto failed" >>/dev/stderr

	exit 1
fi

[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"

echo -n "$NAME: Unmounting '$MNTPNT': " && diskutil eject "$MNTPNT"


exit 0
#EOF
