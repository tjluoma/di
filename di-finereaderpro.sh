#!/usr/bin/env zsh -f
# Purpose: Download and install the latest version of Fine Reader Pro
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-09 ; 2019-11-14 update


NAME="$0:t:r"

echo "$NAME: I hate this stupid app and it's stupid updating system. I give up (for now). @todo"

exit 0




INSTALL_TO='/Applications/FineReader.app'

HOMEPAGE="https://www.abbyy.com/en-us/finereader/pro-for-mac/"

RELEASE_NOTES_URL='https://support.abbyy.com/hc/en-us/articles/360001026229-FineReader-Pro-for-Mac-Change-Log'

DOWNLOAD_PAGE="http://fr7.abbyy.com/mac/fr/ABBYY_FineReader_Pro_ESD.dmg"

SUMMARY="Easily transform paper documents, PDFs and digital photos of text into editable and searchable files. No more manual retyping or reformatting. Instead you can search, share, archive, and copy information from documents for reuse and quotation — saving you time, effort and hassles."

URL="http://fr7.abbyy.com/mac/fr/ABBYY_FineReader_Pro_ESD.dmg"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

LATEST_VERSION=$(curl -sfLS "https://www.abbyy.com/finereader-pro-mac-downloads/" | fgrep 'Build #:' | sed 's#</p>##g ; s#.*>##g' | tr -dc '[0-9]\.')

URL="http://fr7.abbyy.com/mac/fr/ABBYY_FineReader_Pro_ESD.dmg"

if [[ -e "$INSTALL_TO" ]]
then

	SHORT_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleShortVersionString)

	BUNDLE_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleVersion)

	INSTALLED_VERSION=$(echo "$SHORT_VERSION.$BUNDLE_VERSION")

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

else

	FIRST_INSTALL='yes'
fi

FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${LATEST_VERSION}.dmg"

if (( $+commands[lynx] ))
then

	RELEASE_NOTES=$(curl -sfLS "$RELEASE_NOTES_URL" \
		| awk '/<h3>/{i++}i==1' \
		| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin -nonumbers -nolist)

	echo "${RELEASE_NOTES}\n\nSource: ${RELEASE_NOTES_URL}\n\nURL: $URL" | tee "$FILENAME:r.txt"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

(cd "$FILENAME:h" ; echo "\nLocal sha256:" ; shasum -a 256 -p "$FILENAME:t" ) >>| "$FILENAME:r.txt"

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
	mv -f "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.${INSTALLED_VERSION}_${INSTALLED_BUILD}.app"

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

# EOF



## Found this URL -  https://www.abbyy.com/finereader-pro-mac-downloads/
# curl -sfLS "https://www.abbyy.com/finereader-pro-mac-downloads/" | fgrep 'Build #:' | sed 's#</p>##g ; s#.*>##g' | tr -dc '[0-9]\.'
## Result: '12.1.13.1043958'
## 	/Applications/FineReader.app:
## 		CFBundleShortVersionString: 12.1.13
## 		CFBundleVersion: 1043958
##
## Release Notes: <https://support.abbyy.com/hc/en-us/articles/360001026229-FineReader-Pro-for-Mac-Change-Log>
##
## Trial Version <https://downloads.abbyy.com/fr/fr_mac/current/ABBYYFineReaderPro.dmg?secure=EOkGXxyiKvTXMK8VEYyT1g==>
##
## The trial version is the same as the URL version just with a different name
