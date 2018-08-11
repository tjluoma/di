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

	## Where should the app be installed to?
INSTALL_TO='/Applications/Audiobook Builder.app'

	## if installed, get current version. If not, put in 1.0.0
INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo '1.0'`

	## Use installed version in User Agent when requesting Sparkle feed
UA="Audiobook Builder/$INSTALLED_VERSION Sparkle/1.5"

	## This is the 'regular' (non-beta) feed
	## The feed does not include an 'enclosure url'
XML_FEED='http://www.splasm.com/versions/audiobookbuilder.xml'

	# n.b. there is a beta feed but I'm not sure if it is used often and its format is different
	#XML_FEED='http://www.splasm.com/special/audiobookbuilder/audiobookbuilderprerelease_sparkle.xml'

LATEST_VERSION=`curl --connect-timeout 10 -sfL -A "$UA" "$XML_FEED" \
| egrep '<version>.*</version>' \
| head -1 \
| sed 's#</version>##g; s#.*<version>##g;' `

if [[ "$LATEST_VERSION" == "" ]]
then
		## if we didn't get a version string that way, try another way to check if maybe the XML/RSS feed is different
		## This should work for the beta feed, but untested
	LATEST_VERSION=`curl --connect-timeout 10 -sfL -A "$UA" "$XML_FEED" \
	| tr -s ' ' '\012' \
	| egrep '^sparkle:shortVersionString' \
	| head -1 \
	| tr -dc '[0-9].' `

fi

if [[ "$LATEST_VERSION" == "" ]]
then

		## if neither of those two worked, make an incredibly clumsy attempt to check raw HTML of update page
		## this is extremely fragile and should never be used.

	LATEST_VERSION=`curl --connect-timeout 10 -A Safari -sfL http://www.splasm.com/audiobookbuilder/update.html \
			| fgrep -A1 'id="productdesc"' \
			| sed 's#<br>##g; s#.*>##g' \
			| tr -dc '[0-9].'`
fi

	## If none of that worked, give up
if [[ "$LATEST_VERSION" == "" ]]
then
	echo "$NAME: Failed to find LATEST_VERSION from $XML_FEED"
	exit 0
fi

	# If we get here, we got at least _something_ for LATEST_VERSION
	# so compare that against installed version
if [[ "$LATEST_VERSION" == "$INSTALLED_VERSION" ]]
then
	echo "$NAME: Up-To-Date ($INSTALLED_VERSION)"
	exit 0
fi

autoload is-at-least

is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

if [ "$?" = "0" ]
then
	echo "$NAME: Installed version ($INSTALLED_VERSION) is ahead of official version $LATEST_VERSION"
	exit 0
fi

	## If we get here, we need to update
echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"

if [[ -e "$INSTALL_TO/Contents/_MASReceipt/receipt" ]]
then
	echo "$NAME: $INSTALL_TO was installed from the Mac App Store and cannot be updated by this script."
	echo "$NAME: Please use the App Store app to update $INSTALL_TO."
	exit 0
fi

if (( $+commands[lynx] ))
then

	RELEASE_NOTES_URL="$XML_FEED"

	echo "$NAME: Release Notes for $INSTALL_TO:t:r version $LATEST_VERSION:"

	curl -sfL "$RELEASE_NOTES_URL" \
	| sed '1,/<message>/d; /<\/message>/,$d ; s#\]\]\>##g ; s#<\!\[CDATA\[##g' \
	| lynx -dump -nomargins -width=10000 -assume_charset=UTF-8 -pseudo_inlines -stdin

	echo "\nSource: XML_FEED: <$XML_FEED>"
fi

	## Since the XML_FEED doesn't specify an enclosure url, I assume this
	## will always point to the latest version
URL="http://www.splasm.com/downloads/audiobookbuilder/Audiobook%20Builder.dmg"

	## Save the DMG but put the version number in the filename
	## so I'll know what version it is later
FILENAME="$HOME/Downloads/AudioBookBuilder-${LATEST_VERSION}.dmg"

	## tell the user we are downloading it
echo "$NAME: Downloading $URL to $FILENAME"

	## n.b. have to pretend to be Safari or else website will ignore us
curl -A Safari --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

	## Mount the DMG that we downloaded
MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
		| fgrep -A 1 '<key>mount-point</key>' \
		| tail -1 \
		| sed 's#</string>.*##g ; s#.*<string>##g')

	## Make sure that it mounted
if [[ "$MNTPNT" == "" ]]
then
	echo "$NAME: MNTPNT is empty"
	exit 1
fi

	## If there is already an installed version we need to move it aside
if [ -e "$INSTALL_TO" ]
then
		## DON'T quit app
		## because if it is in the middle of making an audiobook
		## that would be Very Bad.
		##
		## Instead, just move it to the Trash and let it keep running
		## until user quits it.

			# move installed version to trash
		mv -vf "$INSTALL_TO" "$HOME/.Trash/AudioBook Builder.$INSTALLED_VERSION.app"
fi

	## tell the user what we are installing, and to where
echo "\n$NAME Installing \"$MNTPNT/Audiobook Builder.app\" to $INSTALL_TO:"

	## This is where it actually installs
	## and, if successful, will unmount/eject the DMG
ditto --noqtn -v "$MNTPNT/Audiobook Builder.app" "$INSTALL_TO" \
&& diskutil eject "$MNTPNT"


exit 0
#EOF
