#!/usr/bin/env zsh -f
# Purpose: Download the direct (not Mac App Store) version of Slack from <https://slack.com>
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-12-17

[[ -e "$HOME/.path" ]] && source "$HOME/.path"

[[ -e "$HOME/.config/di/defaults.sh" ]] && source "$HOME/.config/di/defaults.sh"

INSTALL_TO="${INSTALL_DIR_ALTERNATE-/Applications}/Slack.app"

NAME="$0:t:r"

HOMEPAGE="https://slack.com/"

DOWNLOAD_PAGE="https://slack.com/downloads/mac"

SUMMARY="Slack brings all your communication together — a single place for messaging, tools and files — helping everyone save time and collaborate together."

RELEASE_NOTES_URL='https://slack.com/release-notes/mac'

	# ".ocation" takes care of Location: or location:
URL=$(curl -sfL --head "https://slack.com/ssb/download-osx-universal" \
		| awk -F' |\r' '/^.ocation: /{print $2}' \
		| tail -1 )

LATEST_VERSION=$(echo "$URL:t:r" | tr -dc '[0-9]\.')

if [ "$LATEST_VERSION" = "" -o "$URL" = "" ]
then
	echo "$NAME: Error: bad data received
	URL: $URL
	LATEST_VERSION: $LATEST_VERSION
	"
	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo '0'`

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

	echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"

	if [[ -e "$INSTALL_TO/Contents/_MASReceipt/receipt" ]]
	then
		echo "$NAME: $INSTALL_TO was installed from the Mac App Store and cannot be updated by this script."
		echo "	See <https://apps.apple.com/us/app/slack/id803453959?mt=12> or"
		echo "	<macappstore://apps.apple.com/us/app/slack/id803453959>"
		echo "	Please use the App Store app to update it: <macappstore://showUpdatesPage?scan=true>"
		exit 0
	fi

fi

FILENAME="${DOWNLOAD_DIR_ALTERNATE-$HOME/Downloads}/${${INSTALL_TO:t:r}// /}-${${LATEST_VERSION}// /}.dmg"

	## Save full release notes to an HTML file
curl -sfLS "$RELEASE_NOTES_URL" \
| tidy 	--char-encoding utf8 --clean yes --force-output yes --indent yes --input-xml no --join-classes yes \
		--join-styles yes --markup yes --output-xhtml yes --output-xml no --quiet yes --quote-ampersand yes \
		--quote-marks yes --quote-nbsp no --show-errors 0 --show-warnings no --tidy-mark no \
		--uppercase-attributes no --uppercase-tags no --wrap 0 \
> "$FILENAME:r.html"

if (( $+commands[lynx] ))
then

		# if we have access to lynx, use it on the local HTML file we just saved (and tidy'd)
		# to get just the latest release note changes

	( awk '/<h2>/{i++}i==1' "$FILENAME:r.html" \
		| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin; \
		echo "\nURL: ${URL}\nSource: <$RELEASE_NOTES_URL>" \
	) \
	| tee "$FILENAME:r.txt"

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

echo "$NAME: Unmounting $MNTPNT:"

diskutil eject "$MNTPNT"

exit 0
#EOF
