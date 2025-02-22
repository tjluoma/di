#!/usr/bin/env zsh -f
# Purpose:	Download and install/update the latest version of Toggl Track.
#
# From:		Timothy J. Luoma
# Mail:		luomat at gmail dot com
# Date:		2019-05-22
# Verified:	2025-02-22

## See notes at the bottom of the script regarding beta/non-beta releases

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

INSTALL_TO='/Applications/Toggl Track.app'

RELEASE_NOTES_URL='https://toggl.github.io/toggldesktop/'

		# app is unchanged for 4 years, let's risk it and hard-code values
# INFO=$(curl -sfLS "https://toggl.github.io/toggldesktop/" | awk '/<h3>/{i++}i==1')
# URL=$(echo "$INFO" | tr '"' '\012' | egrep '^https.*\.dmg')
	## CFBundleShortVersionString and CFBundleVersion are identical
# LATEST_VERSION=$(echo "$URL:h:t" | tr -dc '[0-9]\.')

URL='https://github.com/toggl-open-source/toggldesktop/releases/download/v7.5.441/TogglDesktop-7_5_441.dmg'

LATEST_VERSION='7.5.441'

	# If any of these are blank, we cannot continue
if [ "$URL" = "" -o "$LATEST_VERSION" = "" ]
then
	echo "$NAME: Error: bad data received:
	INFO: $INFO
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	"  >>/dev/stderr

	exit 1
fi


if [[ -e "$INSTALL_TO" ]]
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

FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${LATEST_VERSION}.dmg"

if (( $+commands[lynx] ))
then

	RELEASE_NOTES=$(echo "$INFO" \
		| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin -nonumbers -nolist )

	echo "${RELEASE_NOTES}\n\nSource: $RELEASE_NOTES_URL\n\nURL: $URL" | tee "$FILENAME:r.txt"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

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

# XML_FEED='https://assets.toggl.com/installers/darwin_stable_appcast.xml'
# INFO=($(curl -sfLS "$XML_FEED" | tr ' ' '\012' | egrep '^(url|sparkle:version)=' | sort -f | awk -F'"' '//{print $2}'))
# LATEST_VERSION="$INFO[1]"
# URL="$INFO[2]"


# https://toggl.github.io/toggldesktop/download/macos-stable/

# <!DOCTYPE html>
# <html lang="en-US">
#   <meta charset="utf-8">
#   <title>Redirecting&hellip;</title>
#   <link rel="canonical" href="https://github.com/toggl-open-source/toggldesktop/releases/download/v7.4.1036/TogglDesktop-7_4_1036.dmg">
#   <script>location="https://github.com/toggl-open-source/toggldesktop/releases/download/v7.4.1036/TogglDesktop-7_4_1036.dmg"</script>
#   <meta http-equiv="refresh" content="0; url=https://github.com/toggl-open-source/toggldesktop/releases/download/v7.4.1036/TogglDesktop-7_4_1036.dmg">
#   <meta name="robots" content="noindex">
#   <h1>Redirecting&hellip;</h1>
#   <a href="https://github.com/toggl-open-source/toggldesktop/releases/download/v7.4.1036/TogglDesktop-7_4_1036.dmg">Click here if you are not redirected.</a>
# </html>
#
# But that's listed as a beta and not even the latest beta. Here's what the XML_FEED shows at the same time
#
# <?xml version="1.0" encoding="utf-8"?>
# <rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
#     <channel>
#         <title>TogglDesktop Changelog</title>
#         <link>darwin_stable_appcast.xml</link>
#         <description>Most recent changes.</description>
#         <language>en</language>
#         <item>
#             <title>Version 7.4.1034</title>
#             <pubDate>2019-10-25-10-49-48</pubDate>
#             <enclosure url="https://github.com/toggl-open-source/toggldesktop/releases/download/v7.4.1034/TogglDesktop-7_4_1034.dmg" sparkle:version="7.4.1034" length="17752933" type="application/octet-stream" sparkle:dsaSignature="MCwCFE/03VLcS4nQyz7DM0ioE2VHTYSoAhQMlflR1eEzhdhx9go9JhzvCDiMYw==" />
#             <description>
#                 <![CDATA[
#                     <ul>
#                     </ul>
#                 ]]>
#             </description>
#         </item>
#     </channel>
# </rss>
#
#
# What's worse is that 'https://github.com/toggl-open-source/toggldesktop/releases/latest'
# redirects to         'https://github.com/toggl-open-source/toggldesktop/releases/tag/v7.636'
#
# which SEEMS like it should be the latest version since the number is higher, but it is dated 'Apr 25, 2014'


## So, for the time being, I'm going to use 'https://toggl.github.io/toggldesktop/' as canonical, even though
## it's beta. Maybe eventually it will settle down and have more reliable releases
