#!/usr/bin/env zsh -f
# Purpose: Download and install the latest version of Duet Display
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-12, major update 2019-09-09

NAME="$0:t:r"

	# This is where the app will be installed or updated.
if [[ -d '/Volumes/Applications' ]]
then
	INSTALL_TO='/Volumes/Applications/Duet.app'
else
	INSTALL_TO='/Applications/Duet.app'
fi

HOMEPAGE="https://www.duetdisplay.com"

DOWNLOAD_PAGE="https://www.duetdisplay.com/#download"

RELEASE_NOTES_URL='https://www.duetdisplay.com/help-center/mac-release-notes'

SUMMARY="Turn your iPad into an extra display."

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

	## There are two ways of finding the current version.
	## Try them both and compare them to see which is higher

	# First Way
URL1=$(curl -sfLS --head "https://updates.duetdisplay.com/latestMac" | awk -F' |\r' '/^Location/{print $2}')

LV1=$(echo "$URL1:t:r" | sed 's#duet-##g; s#-#.#g')

	# Second Way
URL2=$(curl -sfLS "https://www.duetdisplay.com/help-center/mac-release-notes" | tr '"' '\012' | egrep 'https.*\.zip$')

LV2=$(echo "$URL2:t:r" | sed 's#duet-##g; s#-#.#g')

	# Compare Them
autoload is-at-least

is-at-least "$LV1" "$LV2"

EXIT="$0"

if [[ "$EXIT" == "0" ]]
then
	LATEST_VERSION="$LV1"
	URL="$URL1"
else
	LATEST_VERSION="$LV2"
	URL="$URL2"
fi


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

FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${LATEST_VERSION}.zip"

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

(cd "$FILENAME:h" ; echo "\nLocal sha256:" ; shasum -a 256 -p "$FILENAME:t" ) >>| "$FILENAME:r.txt"

## make sure that the .zip is valid before we proceed
(command unzip -l "$FILENAME" 2>&1 )>/dev/null

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: '$FILENAME' is a valid zip file."

else
	echo "$NAME: '$FILENAME' is an invalid zip file (\$EXIT = $EXIT)"

	mv -fv "$FILENAME" "$INSTALL_TO:h/.Trashes/$UID/"

	mv -fv "$FILENAME:r".* "$INSTALL_TO:h/.Trashes/$UID/"

	exit 0

fi

	## unzip to a temporary directory
UNZIP_TO=$(mktemp -d "${TMPDIR-/tmp/}${NAME}-XXXXXXXX")

echo "$NAME: Unzipping '$FILENAME' to '$UNZIP_TO':"

ditto -xk --noqtn "$FILENAME" "$UNZIP_TO"

EXIT="$?"

if [[ "$EXIT" == "0" ]]
then
	echo "$NAME: Unzip successful"
else
		# failed
	echo "$NAME failed (ditto -xkv '$FILENAME' '$UNZIP_TO')"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then
		# Quit app, if running
		# Note that '-i' to pgrep (ignore case)
	pgrep -ixq "Duet" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "duet" to quit'

	echo "$NAME: Moving existing (old) '$INSTALL_TO' to '$INSTALL_TO:h/.Trashes/$UID/'."

	mv -vf "$INSTALL_TO" "$INSTALL_TO:h/.Trashes/$UID/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then

		echo "$NAME: failed to move existing $INSTALL_TO to $INSTALL_TO:h/.Trashes/$UID/"

		exit 1
	fi
fi

echo "$NAME: Moving new version of '$INSTALL_TO:t' (from '$UNZIP_TO') to '$INSTALL_TO'."

	# Move the file out of the folder
mv -vn "$UNZIP_TO/$INSTALL_TO:t" "$INSTALL_TO"

EXIT="$?"

if [[ "$EXIT" = "0" ]]
then

	echo "$NAME: Successfully installed '$UNZIP_TO/$INSTALL_TO:t' to '$INSTALL_TO'."

else
	echo "$NAME: Failed to move '$UNZIP_TO/$INSTALL_TO:t' to '$INSTALL_TO'."

	exit 1
fi

[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"

exit 0
#EOF

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

