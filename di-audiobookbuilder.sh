#!/bin/zsh -f
# Purpose: Download and install latest version of AudioBook Builder from http://www.splasm.com/audiobookbuilder/
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-12-09

NAME="$0:t:r"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

HOMEPAGE="http://www.splasm.com/audiobookbuilder/"

DOWNLOAD_PAGE="http://www.splasm.com/downloads/audiobookbuilder/Audiobook%20Builder.dmg"

SUMMARY="Audiobook Builder makes it easy to turn your audio CDs and files into audiobooks for your iPhone, iPod or iPad. Join audio, create enhanced chapter stops, adjust quality settings and let Audiobook Builder handle the rest. When it finishes you get one or a few audiobook tracks in iTunes instead of hundreds or even thousands of music tracks!"

	## Since the XML_FEED doesn't specify an enclosure url, I assume this
	## will always point to the latest version
URL="http://www.splasm.com/downloads/audiobookbuilder/Audiobook%20Builder.dmg"

	## Where should the app be installed to?
	# This is where the app will be installed or updated.
if [[ -d '/Volumes/Applications' ]]
then
	INSTALL_TO='/Volumes/Applications/Audiobook Builder.app'
else
	INSTALL_TO='/Applications/Audiobook Builder.app'
fi

	## if installed, get current version. If not, put in 1.0.0
INSTALLED_VERSION=$(defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo '2.0')

INSTALLED_BUILD=$(defaults read "$INSTALL_TO/Contents/Info" CFBundleVersion 2>/dev/null || echo '200')

	## Use installed version in User Agent when requesting Sparkle feed
UA="Audiobook Builder/$INSTALLED_VERSION Sparkle/1.5"

	## This is the 'regular' (non-beta) feed
	## The feed does not include an 'enclosure url'
#XML_FEED='http://www.splasm.com/versions/audiobookbuilder.xml'

## This is the feed for version 2
## Note that version 1 feed did not have build info
XML_FEED='https://www.splasm.com/versions/audiobookbuilder2x.xml'

	# n.b. there is a beta feed but I'm not sure if it is used often and its format is different
	#XML_FEED='http://www.splasm.com/special/audiobookbuilder/audiobookbuilderprerelease_sparkle.xml'

INFO=($(curl --connect-timeout 10 -sfL -A "$UA" "$XML_FEED" \
| egrep '(<version>.*</version>|<bundleVersion>.*</bundleVersion>)' \
| sort \
| head -2 \
| sed 's#</version>##g; s#.*<version>##g; s#</bundleVersion>##g ; s#.*<bundleVersion>##g'))

LATEST_BUILD="$INFO[1]"

LATEST_VERSION="$INFO[2]"


# if [[ "$LATEST_VERSION" == "" ]]
# then
# 		## if we didn't get a version string that way, try another way to check if maybe the XML/RSS feed is different
# 		## This should work for the beta feed, but untested
# 	LATEST_VERSION=`curl --connect-timeout 10 -sfL -A "$UA" "$XML_FEED" \
# 	| tr -s ' ' '\012' \
# 	| egrep '^sparkle:shortVersionString' \
# 	| head -1 \
# 	| tr -dc '[0-9].' `
#
# fi
#
# if [[ "$LATEST_VERSION" == "" ]]
# then
#
# 		## if neither of those two worked, make an incredibly clumsy attempt to check raw HTML of update page
# 		## this is extremely fragile and should never be used.
#
# 	LATEST_VERSION=`curl --connect-timeout 10 -A Safari -sfL http://www.splasm.com/audiobookbuilder/update.html \
# 			| fgrep -A1 'id="productdesc"' \
# 			| sed 's#<br>##g; s#.*>##g' \
# 			| tr -dc '[0-9].'`
# fi

	## If none of that worked, give up
if [ "$LATEST_VERSION" = "" -o "$LATEST_BUILD" = "" ]
then
	echo "$NAME: Failed to find LATEST_VERSION or LATEST_BUILD from $XML_FEED ($LATEST_VERSION/$LATEST_BUILD)"
	exit 0
fi

	# If we get here, we got at least _something_ for LATEST_VERSION
	# so compare that against installed version
if [ "$LATEST_VERSION" = "$INSTALLED_VERSION" -a "$LATEST_BUILD" = "$INSTALLED_BUILD" ]
then
	echo "$NAME: Up-To-Date ($INSTALLED_VERSION/$INSTALLED_BUILD)"
	exit 0
fi

# autoload is-at-least
#
# is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"
#
# if [ "$?" = "0" ]
# then
# 	echo "$NAME: Installed version ($INSTALLED_VERSION) is ahead of official version $LATEST_VERSION"
# 	exit 0
# fi

	## If we get here, we need to update
echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"

if [[ -e "$INSTALL_TO/Contents/_MASReceipt/receipt" ]]
then
	echo "$NAME: $INSTALL_TO was installed from the Mac App Store and cannot be updated by this script."
	echo "	See <https://apps.apple.com/us/app/audiobook-builder/id406226796?mt=12> or"
	echo "	<macappstore://apps.apple.com/us/app/audiobook-builder/id406226796>"
	echo "	Please use the App Store app to update it: <macappstore://showUpdatesPage?scan=true>"
	exit 0
fi

	## Save the DMG but put the version number in the filename
	## so I'll know what version it is later
FILENAME="$HOME/Downloads/AudioBookBuilder-${LATEST_VERSION}_${LATEST_BUILD}.dmg"

if (( $+commands[lynx] ))
then

	RELEASE_NOTES_URL="$XML_FEED"

	( echo "$NAME: Release Notes for $INSTALL_TO:t:r version $LATEST_VERSION / $LATEST_BUILD:" ;
		curl -sfL "$RELEASE_NOTES_URL" \
		| sed '1,/<message>/d; /<\/message>/,$d ; s#\]\]\>##g ; s#<\!\[CDATA\[##g' \
		| lynx -dump -nomargins -width=10000 -assume_charset=UTF-8 -pseudo_inlines -stdin ;
		echo "\nSource: XML_FEED: <$XML_FEED>" ) | tee "$FILENAME:r.txt"
fi

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
	mv -vf "$INSTALL_TO" "$INSTALL_TO:h/.Trashes/$UID/$INSTALL_TO:t:r.${INSTALLED_VERSION}_${INSTALLED_BUILD}.app"
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
