#!/usr/bin/env zsh -f
# Purpose: 	Download and install the latest version of Duet Display
#
# From:		Timothy J. Luoma
# Mail:		luomat at gmail dot com
# Date:		2015-11-12, major update 2019-09-09
# Verified:	2025-02-24

[[ -e "$HOME/.path" ]] && source "$HOME/.path"

[[ -e "$HOME/.config/di/defaults.sh" ]] && source "$HOME/.config/di/defaults.sh"

INSTALL_TO="${INSTALL_DIR_ALTERNATE-/Applications}/Duet.app"

NAME="$0:t:r"

HOMEPAGE="https://www.duetdisplay.com"

DOWNLOAD_PAGE="https://www.duetdisplay.com/#download"

RELEASE_NOTES_URL='https://www.duetdisplay.com/help-center/mac-release-notes'

SUMMARY="Turn your iPad into an extra display."

	## There are two ways of finding the current version.
	## Try them both and compare them to see which is higher

#		## First Way
# 	URL1=$(curl -sfLS --head "https://updates.duetdisplay.com/latestMac" | awk -F' |\r' '/^Location/{print $2}')
#
# 	LV1=$(echo "$URL1:t:r" | sed 's#duet-##g; s#-#.#g')
#
# 		## Second Way
# 	URL2=$(curl -sfLS "https://www.duetdisplay.com/help-center/mac-release-notes" | tr '"' '\012' | egrep 'https.*\.zip$')
#
# 	LV2=$(echo "$URL2:t:r" | sed 's#duet-##g; s#-#.#g')
#
# 		## Compare Them
# 	autoload is-at-least
#
# 	is-at-least "$LV1" "$LV2"
#
# 	EXIT="$0"
#
# 	if [[ "$EXIT" == "0" ]]
# 	then
# 		LATEST_VERSION="$LV1"
# 		URL="$URL1"
# 	else
# 		LATEST_VERSION="$LV2"
# 		URL="$URL2"
# 	fi

URL=$(curl -sfLS --head "https://updates.duetdisplay.com/latestMac" | awk -F' |\r' '/^.ocation/{print $2}' | tail -1)

LATEST_VERSION=$(echo "$URL:t:r" | sed 's#duet-dd-##g; s#-#.#g')

if [ "$LATEST_VERSION" = "" -o "$URL" = "" ]
then
	echo "$NAME: Error: bad data received:
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
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

fi

FILENAME="${DOWNLOAD_DIR_ALTERNATE-$HOME/Downloads}/${${INSTALL_TO:t:r}// /}-${${LATEST_VERSION}// /}.dmg"

if (( $+commands[lynx] ))
then

	RELEASE_NOTES=$(curl -sfLS "$RELEASE_NOTES_URL" \
		| tidy --tidy-mark no --char-encoding utf8 --wrap 0 --show-errors 0 --indent no --input-xml no \
			--output-xml no --quote-nbsp no --show-warnings no --uppercase-attributes no --uppercase-tags no \
			--clean yes --force-output yes --join-classes yes --join-styles yes --markup yes --output-xhtml yes \
			--quiet yes --quote-ampersand yes --quote-marks yes \
		| awk '/<h4>/{i++}i==1' \
		| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin)

	echo "\n${RELEASE_NOTES}\n\nRelease Notes: $RELEASE_NOTES_URL" | tee "$FILENAME:r.txt"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

	# Note the special '-H "Accept-Encoding: gzip,deflate"' otherwise you'll get a 404
curl -H "Accept-Encoding: gzip,deflate" --continue-at - --fail --location --output "$FILENAME" "$URL"

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

##	2019-11-26 - verified that this is still showing _very_ old information
##
## http://updates.duetdisplay.com/checkMacUpdates or https://updates.duetdisplay.com/checkMacUpdates
## redirects to
## https://duet.nyc3.cdn.digitaloceanspaces.com/Mac/2_0/2-0-5-3/DuetDisplayAppcast.xml
##
## which gives this
##
# <rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/" version="2.0">
#     <channel>
#         <title>Duet Display Updates</title>
#         <link>
#             https://duetdisplay.com/DuetDisplayAppcast.xml
#         </link>
#         <description>We have a few important changes for you.</description>
#         <language>en</language>
#         <item>
#             <title>Version 2.0.5.3</title>
#             <description>
#                 <![CDATA[
#                     <ul> <li>Stability fixes</li>
#                     <li>Performance upgradese</li>
#                     <li>macOS Mojave upgrades</li>
#                     <li>macOS Mojave Hardware Acceleration</li>
#                     </ul>
#                 ]]>
#             </description>
#             <pubDate>11 March 2019</pubDate>
#             <enclosure url="https://duet.nyc3.cdn.digitaloceanspaces.com/Mac/2_0/duet-2-0-5-3.zip" sparkle:version="2.0.5.3" length="23809834" type="application/octet-stream"/>
#         </item>
#     </channel>
# </rss>
##
## But 2.0.5.3 is an old version. 2.0.7.4 is the current (as far as I know) version
##
##
## This one is even older: "https://updates.devmate.com/com.kairos.duet.xml" (hasn't been updated since 2015)
##
## 2019-09-09 - this URL "https://www.duetdisplay.com/mac/" now redirects to 'https://help.duetdisplay.com/updates'

#EOF
