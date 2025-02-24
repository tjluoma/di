#!/usr/bin/env zsh -f
# Purpose: 	Download and install the latest version of CocaPacketAnalyzer
#
# From:		Timothy J. Luoma
# Mail:		luomat at gmail dot com
# Date:		2016-03-19; 2019-07-31
# Verified:	2025-02-24

# @TODO - release notes do not work

NAME="$0:t:r"

INSTALL_TO='/Applications/CocoaPacketAnalyzer.app'

HOMEPAGE="http://www.tastycocoabytes.com/cpa/"

DOWNLOAD_PAGE="http://www.tastycocoabytes.com/cpa/"

SUMMARY="Cocoa Packet Analyzer is a native Mac OS X implementation of a network protocol analyzer and packet sniffer. CPA supports the industry-standard PCAP packet capture format for reading, capturing and writing packet trace files."

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

	# OLD
	# XML_FEED='http://www.tastycocoabytes.com/cpa/updates/appcast.xml'

XML_FEED='https://www.tastycocoabytes.com/cpa/updates/appcast2.xml'

INFO=$(curl -sfLS "$XML_FEED" \
		| awk '/<item>/{i++}i==1' \
		| tr -s '\012' ' ')

RELEASE_NOTES_URL=$(echo "$INFO" | sed 's#.*<sparkle:releaseNotesLink>##g; s#</sparkle:releaseNotesLink>.*##g')

LATEST_VERSION=$(echo "$INFO" | sed 's#.*<sparkle:shortVersionString>##g; s#</sparkle:shortVersionString>.*##g')

LATEST_BUILD=$(echo "$INFO" | sed 's#.*<sparkle:version>##g; s#</sparkle:version>.*##g')

URL=$(echo "$INFO" | sed 's#.*enclosure url="##g; s#" .*##g')

	# If any of these are blank, we should not continue
if [ "$INFO" = "" -o "$LATEST_VERSION" = ""  -o "$LATEST_BUILD" = "" -o "$URL" = "" ]
then
	echo "$NAME: Error: bad data received:
	INFO: 			$INFO
	LATEST_VERSION:	$LATEST_VERSION
	LATEST_BUILD: 	$LATEST_BUILD
	URL: 			$URL
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

	if [[ ! -w "$INSTALL_TO" ]]
	then
		echo "$NAME: '$INSTALL_TO' exists, but you do not have 'write' access to it, therefore you cannot update it." >>/dev/stderr

		exit 2
	fi

	if [[ -e "$INSTALL_TO/Contents/_MASReceipt/receipt" ]]
	then
		echo "$NAME: $INSTALL_TO was installed from the Mac App Store and cannot be updated by this script."
		echo "	See <https://apps.apple.com/us/app/cocoa-packet-analyzer/id418357707?mt=12> or"
		echo "	<macappstore://apps.apple.com/us/app/cocoa-packet-analyzer/id418357707>"
		echo "	Please use the App Store app to update it: <macappstore://showUpdatesPage?scan=true>"
		exit 0
	fi

else

	FIRST_INSTALL='yes'
fi

FILENAME="${DOWNLOAD_DIR_ALTERNATE-$HOME/Downloads}/${${INSTALL_TO:t:r}// /}-${${LATEST_VERSION}// /}_${${LATEST_BUILD}// /}.dmg"

RELEASE_NOTES_TXT="$FILENAME:r.txt"

if [[ -e "$RELEASE_NOTES_TXT" ]]
then

	cat "$RELEASE_NOTES_TXT"

else

	if (( $+commands[lynx] ))
	then

		RELEASE_NOTES=$(curl -sfLS "$RELEASE_NOTES_URL" \
		| lynx -dump -width='10000' -display_charset=UTF-8 -assume_charset=UTF-8 -pseudo_inlines -stdin  -nomargins -nonumbers)

		echo "${RELEASE_NOTES}\n\nSource: ${RELEASE_NOTES_URL}\nVersion: ${LATEST_VERSION} / ${LATEST_BUILD}\nURL: ${URL}" | tee "$RELEASE_NOTES_TXT"

	fi

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

(cd "$FILENAME:h" ; echo "\nLocal sha256:" ; shasum -a 256 "$FILENAME:t" ) >>| "$FILENAME:r.txt"

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

[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"

exit 0
#EOF
