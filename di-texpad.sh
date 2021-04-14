#!/usr/bin/env zsh -f
# Purpose: Download and install the latest version of Texpad
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2016-01-19

NAME="$0:t:r"

INSTALL_TO="/Applications/Texpad.app"

XML_FEED="https://www.texpadapp.com/static-collected/upgrades/texpadappcast.xml"

HOMEPAGE="https://www.texpadapp.com"

DOWNLOAD_PAGE="https://www.texpad.com/osx"

SUMMARY="Texpad is a LaTeX editor designed for fast navigation around projects of all sizes. Given a single LaTeX root file, it will read through the LaTeX source, and that of all included files to present you with an outline of your project. Similarly Texpad reads the LaTeX console output, finding errors, and presenting them in a table you can use to jump straight to the errors in the LaTeX source."

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

# NOTE: This is a very unusual case. Rather than including the CFBundleShortVersionString in a 'sparkle:shortVersionString' field
# in the RSS feed, the LATEST_VERSION information appears to be shown only in the '<title>' field of the appropriate entry
# AND we need to skip the _first_ '<title>' because it is the <title> of the feed itself, whereas we want the
# <title> of the first _entry_ in the feed

IFS=$'\n' INFO=($(curl -sfL "$XML_FEED" \
		| fgrep -vi '<title>Texpad</title>' \
		| egrep '<title>.*</title>|sparkle:version=|url=' \
		| head -3 \
		| sed 's#^[ 	]*##g' \
		| sort ))

## We end up with 3 lines, which should look something like this:
# <enclosure url="https://download.texpadapp.com/apps/osx/updates/Texpad_1_8_5__404__f8f30e5.dmg"
# <title>Texpad 1.8.5 (404)</title>
# sparkle:version="404"
## Note that '404' is the LATEST_BUILD number, and it too appears in the <title> so we need to
## remove that from the LATEST_VERSION information, and _then_ we can get the LATEST_VERSION
## info by removing everything except digits and any literal '.'

URL=`echo "$INFO[1]" | sed 's#<enclosure url="##g ; s#"##g;'`

LATEST_BUILD=`echo "$INFO[3]" | tr -dc '[0-9]'`

	# Make sure we get LATEST_BUILD _before_ we try to get this
LATEST_VERSION=`echo "$INFO[2]" | sed "s#\(${LATEST_BUILD}\)##g;" | tr -dc '[0-9]\.'`

	# If any of these are blank, we should not continue
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

	FIRST_INSTALL='no'

	if [[ -e "$INSTALL_TO/Contents/_MASReceipt/receipt" ]]
	then
		echo "$NAME: $INSTALL_TO was installed from the Mac App Store and cannot be updated by this script."
		echo "	See <https://apps.apple.com/us/app/texpad-latex-editor/id458866234?mt=12> or"
		echo "	<macappstore://apps.apple.com/us/app/texpad-latex-editor/id458866234>"
		echo "	Please use the App Store app to update it: <macappstore://showUpdatesPage?scan=true>"
		exit 0
	fi

else

	FIRST_INSTALL='yes'
fi

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}_${LATEST_BUILD}.dmg"

if (( $+commands[lynx] ))
then

	RELEASE_NOTES_URL=$(curl -sfL "$XML_FEED" \
		| fgrep '<sparkle:releaseNotesLink>' \
		| head -1 \
		| sed 's#.*<sparkle:releaseNotesLink>##g ; s#</sparkle:releaseNotesLink>##g')

	( echo -n "$NAME: Release Notes for" ;
		curl -sfL "$RELEASE_NOTES_URL" \
		| fgrep -vi 'Auto-update from within Texpad or download' \
		| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin \
		| sed 's#^ *# #g' ;
		echo "\nSource: <$RELEASE_NOTES_URL>" ) | tee "$FILENAME:r.txt"

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
fi

if [[ -e "$INSTALL_TO" ]]
then
		# Quit app, if running
	pgrep -xq "$INSTALL_TO:t:r" \
	&& LAUNCH='yes' \
	&& osascript -e "tell application \"$INSTALL_TO:t:r\" to quit"

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"
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

echo "$NAME: Unmounting $MNTPNT:"

diskutil eject "$MNTPNT"

exit 0
EOF
