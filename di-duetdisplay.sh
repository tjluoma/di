#!/usr/bin/env zsh -f
# Purpose: Download and install the latest version of Duet Display
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-12

NAME="$0:t:r"

INSTALL_TO='/Applications/Duet.app'

HOMEPAGE="https://www.duetdisplay.com"

DOWNLOAD_PAGE="https://www.duetdisplay.com/#download"

RELEASE_NOTES_URL='https://help.duetdisplay.com/updates/mac-release-notes'

SUMMARY="Turn your iPad into an extra display."

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

# https://help.duetdisplay.com/updates/mac-release-notes now has links to recent downloads

## curl -sfLS "https://help.duetdisplay.com/updates/mac-release-notes"| tidy -config ~/.config/tidy/basic-clean-reformat-no-indent.rc | awk '/<p><strong>Version/{i++}i==1'

URL=$(curl -sfLS "https://help.duetdisplay.com/updates/mac-release-notes" | tr '"' '\012' | egrep '^https://duet.*\.zip' | head -1)

LATEST_VERSION=$(echo "$URL:t:r" | sed 's#duet-##g; s#-#.#g')

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

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}.zip"

# if (( $+commands[lynx] ))
# then
#
# 	( echo "$NAME: Release Notes for $INSTALL_TO:t:r ${LATEST_VERSION}: " ;
# 		curl -sfLS "$XML_FEED" \
# 		| sed 	-e '1,/<item>/d; /<\/item>/,$d' \
# 				-e '1,/<description>/d; /<\/description>/,$d' \
# 				-e 's#\]\]\>##g ; s#<\!\[CDATA\[##g' \
# 		| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin) \
# 	| tee "$FILENAME:r.txt"
#
# fi

echo "$NAME: Downloading $URL to $FILENAME"

	# Note the special '-H "Accept-Encoding: gzip,deflate"' otherwise you'll get a 404
curl -H "Accept-Encoding: gzip,deflate" --continue-at - --fail --location --output "$FILENAME" "$URL"

[[ ! -e "$FILENAME" ]] && echo "$NAME: No file found at $FILENAME" && exit 0

if [ -e "$INSTALL_TO" ]
then
		# Quit app, if running
		# Note that '-i' to pgrep
	pgrep -ixq "Duet" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "Duet" to quit'

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/Duet.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

ditto --noqtn -xk "$FILENAME" "$INSTALL_TO:h/"

EXIT="$?"

if [ "$EXIT" = "0" ]
then

	echo "$NAME: Installed/updated $INSTALL_TO"

else
	echo "$NAME: 'ditto' failed (\$EXIT = $EXIT)"

	exit 1
fi


exit 0
#EOF



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

