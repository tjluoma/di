#!/usr/bin/env zsh -f
# Purpose: Download and install the latest version of EncryptMe (née Cloak)
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-06

NAME="$0:t:r"

INSTALL_TO='/Applications/EncryptMe.app'

HOMEPAGE="https://encrypt.me"

DOWNLOAD_PAGE="https://app.encrypt.me/transition/download/osx/latest/"

SUMMARY="Encrypt.me (formerly “Cloak”) aims to provide people the tools they need to stay safe online. Through our simple, easy-to-use apps, encrypted connections are easy to achieve. Once you install Encrypt.me, it automatically detects unsafe networks and secures your web access."

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

XML_FEED='https://www.getcloak.com/updates/osx/public/'

	# 2020-06-05 - as of version 4.2.1 / 26 Feb 2020 the feed now shows both
	# sparkle:shortVersionString and sparkle:version
INFO=($(curl -sfL "$XML_FEED" \
		| tr ' ' '\012' \
		| egrep '^(url|sparkle:shortVersionString|sparkle:version)=' \
		| tail -3 \
		| sort \
		| awk -F'"' '//{print $2}'))

	# 'sort' in the INFO= line should keep this consistent
LATEST_VERSION="$INFO[1]"

LATEST_BUILD="$INFO[2]"

URL="$INFO[3]"

if [ "$INFO" = "" -o "$LATEST_VERSION" = ""  -o "$LATEST_BUILD" = "" -o "$URL" = "" ]
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

	if [[ ! -w "$INSTALL_TO" ]]
	then
		echo "$NAME: '$INSTALL_TO' exists, but you do not have 'write' access to it, therefore you cannot update it." >>/dev/stderr

		exit 2
	fi

else

	FIRST_INSTALL='yes'
fi

FILENAME="$HOME/Downloads/${${INSTALL_TO:t:r}// /}-${${LATEST_VERSION}// /}_${${LATEST_BUILD}// /}.dmg"

if (( $+commands[lynx] ))
then

	if [[ -e "$FILENAME:r.txt" ]]
	then

		cat "$FILENAME:r.txt"

	else

		RELEASE_NOTES_URL="$XML_FEED"

		( echo -n "$NAME: Release Notes for ";
			curl -sfL "$RELEASE_NOTES_URL" \
			| sed 	-e "1,/<title>Encrypt.me $LATEST_VERSION<\/title>/d" \
					-e '/<pubDate>/,$d' \
					-e "s#<description><\!\[CDATA\[##g ; s#\]\]>##g" \
			| lynx -dump -nomargins -width=10000 -assume_charset=UTF-8 -pseudo_inlines -stdin ;
			echo "\nSource: XML_FEED <${RELEASE_NOTES_URL}>" ) | tee "$FILENAME:r.txt"
	fi

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

egrep -q '^Local sha256:$' "$FILENAME:r.txt" 2>/dev/null

EXIT="$?"

if [ "$EXIT" = "1" -o ! -e "$FILENAME:r.txt" ]
then
	(cd "$FILENAME:h" ; \
	echo "\n\nLocal sha256:" ; \
	shasum -a 256 -p "$FILENAME:t" \
	)  >>| "$FILENAME:r.txt"
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
	echo "$NAME: moving old installed version to '$TRASH'..."
	mv -f "$INSTALL_TO" "$TRASH/$INSTALL_TO:t:r.${INSTALLED_VERSION}_${INSTALLED_BUILD}.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then

		echo "$NAME: failed to move '$INSTALL_TO' to '$TRASH'. ('mv' \$EXIT = $EXIT)"

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
