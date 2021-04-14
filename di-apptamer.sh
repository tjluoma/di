#!/usr/bin/env zsh -f
# Purpose: Download and install / update the latest version of App Tamer
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2019-12-12

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

INSTALL_TO='/Applications/App Tamer.app'

	## alternatively:
	# XML_FEED='https://www.stclairsoft.com/cgi-bin/sparkle.cgi?AT&id=A483E71F448B'
XML_FEED='https://www.stclairsoft.com/updates/AppTamer.xml'

INFO=$(curl -sfLS "$XML_FEED" \
	| sed 's#^[	 ]*##g' \
	| tr -s '\012|\r| ' ' ' \
	| sed -e 's#> <#><#g' -e 's#> #>#g' -e 's# <#<#g')

URL=$(echo "$INFO" | sed -e 's#.* url="##g' -e 's#" .*##g')

RELEASE_NOTES_URL=$(echo "$INFO" | sed -e 's#.*<sparkle:releaseNotesLink xml:lang="en">##g' -e 's#</sparkle:releaseNotesLink>.*##')

LATEST_VERSION=$(echo "$INFO" | sed -e 's#.* sparkle:shortVersionString="##g' -e 's#" .*##g')

LATEST_BUILD=$(echo "$INFO" | sed -e 's#.* sparkle:version="##g' -e 's#" .*##g')

	# If any of these are blank, we cannot continue
if [ "$INFO" = "" -o "$RELEASE_NOTES_URL" = "" -o "$URL" = "" -o "$LATEST_VERSION" = ""  -o "$LATEST_BUILD" = "" ]
then
	echo "$NAME: Error: bad data received:
	INFO: $INFO
	URL: $URL
	LATEST_VERSION: $LATEST_VERSION
	LATEST_BUILD: $LATEST_BUILD
	RELEASE_NOTES_URL: $RELEASE_NOTES_URL
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

	if [[ ! -w "$INSTALL_TO" ]]
	then
		echo "$NAME: '$INSTALL_TO' exists, but you do not have 'write' access to it, therefore you cannot update it." >>/dev/stderr

		exit 2
	fi

else

	FIRST_INSTALL='yes'
fi

FILENAME="${DOWNLOAD_DIR-$HOME/Downloads}/${${INSTALL_TO:t:r}// /}-${${LATEST_VERSION}// /}_${${LATEST_BUILD}// /}.dmg"

if (( $+commands[lynx] ))
then

	 RELEASE_NOTES=$(curl -sfLS "$RELEASE_NOTES_URL" \
	 				 | awk '/<h3>/{i++}i==1' \
	 				 | lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin -nonumbers -nolist)

	echo "${RELEASE_NOTES}\n\nSource: ${RELEASE_NOTES_URL}\nURL: $URL" | tee "$FILENAME:r.txt"

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


# curl "https://www.stclairsoft.com/cgi-bin/sparkle.cgi?AT&id=A483E71F448B&osVersion=10.14.6&cputype=7&cpu64bit=1&cpusubtype=8&model=MacBookAir8,1&ncpu=4&lang=en-US&appName=App%20Tamer&appVersion=2.4.9&cpuFreqMHz=1600&ramMB=16384" \
#   -H "Accept: application/rss+xml,*/*;q=0.1" \
#   -H "Accept-Language: en-us" \
#   -H "User-Agent: App Tamer/2.4.9 Sparkle/1.22.0"
#

exit 0
#EOF
