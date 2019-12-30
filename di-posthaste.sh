#!/usr/bin/env zsh -f
# Purpose: Post Haste is a free project management tool that allows you to setup file and folder templates for your projects.
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2019-11-22

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

	# This is where the app will be installed or updated.
if [[ -d '/Volumes/Applications' ]]
then
	INSTALL_TO='/Volumes/Applications/Post Haste.app'
else
	INSTALL_TO='/Applications/Post Haste.app'
fi

HOMEPAGE='https://www.digitalrebellion.com/posthaste/'

TEMPFILE="${TMPDIR-/tmp}/${NAME}.${TIME}.$$.$RANDOM.xml"

XML_FEED="https://www.digitalrebellion.com/rss/appcast?app=posthaste&subapp=posthaste"

	# save the feed
curl -sfLS "$XML_FEED" | sed 's#^ *##g' | tr -d '\r|\012' >| "$TEMPFILE"

URL_RAW=$(sed -e 's#.*enclosure url="##g' -e 's#" .*##g' "$TEMPFILE")

LATEST_BUILD=$(sed -e 's#.*sparkle:version="##g' -e 's#" .*##g' "$TEMPFILE")

LATEST_VERSION=$(sed -e 's#.*sparkle:shortVersionString="##g' -e 's#" .*##g' "$TEMPFILE")

CHECKSUM=$(sed -e 's#.*checksum="##g' -e 's#" .*##g' "$TEMPFILE")

RELEASE_NOTES_RAW=$(sed -e 's#.*<description>##g' -e 's#</description>.*##g' "$TEMPFILE")

if [ "$URL_RAW" = "" -o "$LATEST_BUILD" = ""  -o "$LATEST_VERSION" = ""  -o "$CHECKSUM" = "" ]
then

	echo "$NAME: Fatal error. Check info below:

	URL_RAW: ${URL_RAW}

	LATEST_BUILD: ${LATEST_BUILD}

	LATEST_VERSION: ${LATEST_VERSION}

	CHECKSUM: ${CHECKSUM}

	RELEASE_NOTES_RAW: ${RELEASE_NOTES_RAW}

	Source: $XML_FEED
	"

	exit 1

fi

	## URL is usually something like this
	# 	https://www.digitalrebellion.com/download/posthaste?version=2650
	# which translates to something like this
	# 	https://digitalrebellion-downloads.s3.amazonaws.com/posthaste/Post_Haste_for_Mac_2650.dmg
	# I want the latter, and this is how I get it
URL=$(curl --head -sfLS "$URL_RAW" | awk -F' |\r' '/^.ocation:/{print $2}')

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

else

	FIRST_INSTALL='yes'
fi

FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${LATEST_VERSION}_${LATEST_BUILD}.dmg"

CHECKSUM_FILE="$FILENAME:r.checksum.txt"

if (( $+commands[lynx] ))
then

	RELEASE_NOTES=$(echo "$RELEASE_NOTES_RAW" \
		| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin -nonumbers -nolist \
		| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin -nonumbers -nolist)

	echo "${RELEASE_NOTES}\n\nURL: $URL" | tee "$FILENAME:r.txt"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

	## We have an actual checksum from the XML_FEED, so we'll use that instead
	# (cd "$FILENAME:h" ; echo "\nLocal sha256:" ; shasum -a 256 -p "$FILENAME:t" ) >>| "$FILENAME:r.txt"

echo "$CHECKSUM ?$FILENAME:t" >| "$CHECKSUM_FILE"

shasum -c "$CHECKSUM_FILE"

EXIT="$?"

if [ "$EXIT" = "0" ]
then

	echo "$NAME: Checksum verified: '$FILENAME:t'"

else

	echo "$NAME: Checksum FAILED: '$FILENAME:t' (\$EXIT = $EXIT)"

	exit 1

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

exit 0

#EOF
