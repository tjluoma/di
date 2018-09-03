#!/bin/zsh -f
# Purpose:
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-08-22

NAME="$0:t:r"

INSTALL_TO="/Applications/StackMenu.app"

HOMEPAGE="http://basilsalad.com/os-x/stack-menu"

DOWNLOAD_PAGE="http://shine.basilsalad.com/download.php?id=1"

SUMMARY="Stack Menu stays in your menu bar that gives you instant access to Stack Overflow. Say hello to speedy solutions and goodbye to search engine seductions."

DOWNLOAD="http://shine.basilsalad.com/download.php?id=1"

XML_FEED="https://shine.basilsalad.com/appcast.php?id=1"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

function do_exit {

	mv -f "$TEMPFILE" "$HOME/.Trash/"

	exit "$@"
}

zmodload zsh/datetime

TIME=`strftime "%Y-%m-%d--%H.%M.%S" "$EPOCHSECONDS"`

function timestamp { strftime "%Y-%m-%d--%H.%M.%S" "$EPOCHSECONDS" }

if [[ -e "$INSTALL_TO" ]]
then

	SPARKLE_VER=$(defaults read "$INSTALL_TO/Contents/Frameworks/Sparkle.framework/Versions/A/Resources/Info.plist" CFBundleShortVersionString)
	INSTALLED_VERSION=$(defaults read "$INSTALL_TO/Contents/Info.plist" CFBundleShortVersionString)

else
	SPARKLE_VER='1.20.0'
	INSTALLED_VERSION="1.0"
fi

TEMPFILE="$HOME/.$NAME.$TIME.xml"

curl -sSfL "${XML_FEED}" \
		-H "Accept: application/rss+xml,*/*;q=0.1" \
		-H "Cookie: spfs=k20dg6vsd4mgdb21b0e3pvher1" \
		-H "User-Agent: Stack Menu/$INSTALLED_VERSION Sparkle/$SPARKLE_VER" \
		-H "Accept-Language: en-us" > "$TEMPFILE"

[[ ! -s "$TEMPFILE" ]] && echo "$NAME: Failed to retrieve data from '$XML_FEED'" && do_exit 1

	# yes, it's a useless use of cat. Get over it.
INFO=($(cat "$TEMPFILE" \
		| tr -s ' ' '\012' \
		| egrep 'sparkle:version|sparkle:shortVersionString|url=' \
		| head -3 \
		| sort \
		| awk -F'"' '/^/{print $2}'))

	# "Sparkle" will always come before "url" because of "sort"
LATEST_VERSION="$INFO[1]"
LATEST_BUILD="$INFO[2]"
URL="$INFO[3]"

URL=$(echo "$URL" | sed 's#amp;##g')

	# If any of these are blank, we cannot continue
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

else

	FIRST_INSTALL='yes'
fi

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}_${LATEST_BUILD}.dmg"

if (( $+commands[lynx] ))
then

	RELEASE_NOTES_URL="$XML_FEED"

	(echo "$NAME: Release Notes for $INSTALL_TO:t:r ($LATEST_VERSION/$LATEST_BUILD):" ;
	 cat "$TEMPFILE" | \
	 sed  -e '1,/<item>/d; /<enclosure /,$d ; s#.*<pubDate>#<p>Published: #g' \
	 	 -e 's#<\/pubDate>#</p>#g ; s#\<\!\[CDATA\[##g ; s#\]\]\>##g' \
		| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin;
		echo "\nSource: XML_FEED <$RELEASE_NOTES_URL>") \
	 | tee -a "$FILENAME:r.txt"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl -H "Accept: application/rss+xml,*/*;q=0.1" \
	-H "Cookie: spfs=k20dg6vsd4mgdb21b0e3pvher1" \
	-H "User-Agent: Stack Menu/1.0 Sparkle/1.20.0" \
	-H "Accept-Language: en-us" \
	--continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## do_exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && do_exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && do_exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && do_exit 0

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
	&& osascript -e 'tell application "$INSTALL_TO:t:r" to quit'

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
