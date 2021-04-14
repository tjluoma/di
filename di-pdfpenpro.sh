#!/usr/bin/env zsh -f
# Purpose: Download and install PDFPenPro version 12 from <https://smilesoftware.com/pdfpenpro/>
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-08-21


## @todo - feed is now at 'https://smilesoftware.com/cgi-bin/pdfpenpro_update.pl' as of 2020-11-30

NAME="$0:t:r"

INSTALL_TO='/Applications/PDFpenPro.app'

HOMEPAGE="https://smilesoftware.com/PDFpenPro"

DOWNLOAD_PAGE="https://dl.smilesoftware.com/com.smileonmymac.PDFpenPro/PDFpenPro.dmg"

SUMMARY="Powerful PDF Editing On Your Mac. Add signatures, text, and images. Make changes and correct typos. OCR scanned docs. Fill out and create forms. Export to Microsoft Word, Excel, PowerPoint."

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

XML_FEED='https://smilesoftware.com/appcast/PDFpenPro12.xml'

INFO=$(curl -sfLS "$XML_FEED" | tr -d '\012' | tr -s ' ' ' ')

LATEST_VERSION=$(echo "$INFO" | sed -e 's#.*sparkle:shortVersionString="##g' -e 's#".*##g')

LATEST_BUILD=$(echo "$INFO" | sed -e 's#.*sparkle:version="##g' -e 's#".*##g')

URL=$(echo "$INFO" | sed -e 's#.*enclosure url="##g' -e 's#".*##g')



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
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION/$INSTALLED_BUILD) $ASTERISK"
		exit 0
	fi

	echo "$NAME: Outdated: $INSTALLED_VERSION/$INSTALLED_BUILD vs $LATEST_VERSION/$LATEST_BUILD"

	FIRST_INSTALL='no'

	if [[ -e "$INSTALL_TO/Contents/_MASReceipt/receipt" ]]
	then
		echo "$NAME: $INSTALL_TO was installed from the Mac App Store and cannot be updated by this script."

		if [[ "$ITUNES_URL" != "" ]]
		then
			echo "	See <https://$ITUNES_URL?mt=12> or"
			echo "	<macappstore://$ITUNES_URL>"
		fi

		echo "	Please use the App Store app to update it: <macappstore://showUpdatesPage?scan=true>"
		exit 0
	fi

else

	FIRST_INSTALL='yes'
fi

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}_${LATEST_BUILD}.dmg"

RELEASE_NOTES_TXT="$FILENAME:r.txt"

if [[ -e "$RELEASE_NOTES_TXT" ]]
then

	cat "$RELEASE_NOTES_TXT"

else

	if (( $+commands[lynx] ))
	then

		RELEASE_NOTES_HTML=$(echo "$INFO" | \
			sed	-e 's#Please note that PDFpenPro 12 is a paid upgrade for users of PDFpenPro 11 and earlier.##g' \
				-e 's#.*\<\!\[CDATA\[##g' \
				-e 's#\]\]\>.*##g')

	(echo "$RELEASE_NOTES_HTML" \
		| lynx -dump -width='10000' -display_charset=UTF-8 -assume_charset=UTF-8 -pseudo_inlines -stdin -nomargins;
		echo "\nSource: <$XML_FEED>" ) | tee "$FILENAME:r.txt"

	fi

fi

## Download it

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

#
#EOF
