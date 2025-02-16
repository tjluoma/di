#!/usr/bin/env zsh -f
# Purpose: Download latest version of Cisdem OCRWizard from https://www.cisdem.com/ocr-wizard-mac.html
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2019-06-18

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

# Found XML_FEED here but it is 404 not found
# https://updates.devmate.com/com.cisdem.pdfconverterocr.xml

INSTALL_TO='/Applications/Cisdem OCRWizard.app'

# There's no feed for this AND the URL does not necessarily reflect the version number
# so we have to get a bit creative.
#
# I am _assuming_ that the URL will change when the app is updated, but that might not be true

	# get the URL to the current DMG from the website
URL=$(curl -sfLS "https://www.cisdem.com/ocr-wizard-mac.html" | tr '"' '\012' | egrep '^http.*\.dmg$' | head -1)

if [[ "$URL" == "" ]]
then
	echo "$NAME: 'URL' is empty."
	exit 1
fi

	# Have we seen the current URL before? If so it should be at the end of this file
egrep -q "^$URL	" "$0"

	# this should be 0 if we have seen the URL before
EXIT="$?"

if [ "$EXIT" = "0" ]
then
		# if we get here then we HAVE seen this URL before
	LATEST_VERSION=$(egrep "^$URL	" "$0" | awk '{print $2}' | tail -1)

else

		# if we haven't seen this URL before, we don't know what the
		# version number is, so we'll use 'new' as a placeholder

	LATEST_VERSION='new'

fi

	# if the app is installed AND the latest version is not a version we've never
	# seen before, then we compare the installed version to the latest version
if [ -e "$INSTALL_TO" -a "$LATEST_VERSION" != "new" ]
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

else

	FIRST_INSTALL='yes'

fi

	# if we get here, we need to download a new version of the app
FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${LATEST_VERSION}.dmg"

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

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

	## OK, so now we have the app installed, but we need to prepare for what happens
	## the next time we run this script. We need to update it to say what the URL
	## is and what the version number associated with that URL is.
	## So let's start by getting the version that we just installed:
LATEST_VERSION=$(defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString)

	## if we didn't get anything, holler and quit
[[ "$LATEST_VERSION" == "" ]] \
	&& echo "$NAME: '$LATEST_VERSION' of '$INSTALL_TO' is empty!" \
	&& exit 1

	## if we did get something, append the URL and the version number to this file
echo "\n${URL}\t${LATEST_VERSION}" >>| "$0"

	## rename the downloaded file to include the actual version number
mv -vn "$FILENAME" "$FILENAME:h/CisdemOCRWizard-${LATEST_VERSION}.dmg"

exit 0

## below is a log of URLs and the versions that they are associated with

https://www.cisdem.com/downloads/cisdem-ocrwizard-41.dmg	4.3.0

https://www.cisdem.com/downloads/cisdem-ocrwizard-41.dmg	4.3.0
