#!/bin/zsh -f
# Purpose: Download and install the latest version of EncryptMe nee Cloak
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-06

## 2018-07-10 - renamed di-cloak to di-encryptme to reflect new name

NAME="$0:t:r"

INSTALL_TO='/Applications/EncryptMe.app'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

XML_FEED='https://www.getcloak.com/updates/osx/public/'

	# No other version info in feed
INFO=($(curl -sfL "$XML_FEED" \
		| tr ' ' '\012' \
		| egrep '^(url|sparkle:version)=' \
		| tail -2 \
		| awk -F'"' '//{print $2}'))

URL="$INFO[1]"

LATEST_VERSION="$INFO[2]"

if [ "$INFO" = "" -o "$LATEST_VERSION" = "" -o "$URL" = "" ]
then
	echo "$NAME: Error: bad data received:
	INFO: $INFO
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString`

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

if (( $+commands[lynx] ))
then

	RELEASE_NOTES_URL="$XML_FEED"

	echo -n "$NAME: Release Notes for "

	curl -sfL "$RELEASE_NOTES_URL" \
	| sed "1,/<title>Encrypt.me $LATEST_VERSION<\/title>/d ; /<pubDate>/,\$d ; s#<description><\!\[CDATA\[##g ; s#\]\]>##g" \
	| lynx -dump -nomargins -width=10000 -assume_charset=UTF-8 -pseudo_inlines -stdin

	echo "\nSource: XML_FEED <${RELEASE_NOTES_URL}>"

fi

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-$LATEST_VERSION.dmg"

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
		| fgrep -A 1 '<key>mount-point</key>' \
		| tail -1 \
		| sed 's#</string>.*##g ; s#.*<string>##g')

if [[ "$MNTPNT" == "" ]]
then
		echo "$NAME: Failed to mount $FILENAME. (MNTPNT is empty)"
		exit 0
fi

echo "$MNTPNT"

if [ -e "$INSTALL_TO" ]
then
		# Quit app, if running
	pgrep -xq "EncryptMe" \
	&& LAUNCH='yes' \
	&& killall EncryptMe

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/EncryptMe.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

ditto --noqtn "$MNTPNT/EncryptMe.app" "$INSTALL_TO"

EXIT="$?"

if [ "$EXIT" = "0" ]
then

	echo "$NAME: Updated $INSTALL_TO"

else
	echo "$NAME: 'ditto' failed (\$EXIT = $EXIT)"

	exit 1
fi

diskutil eject "$MNTPNT"

[[ "$LAUNCH" == "yes" ]] && open -a "$INSTALL_TO"

exit 0
#EOF
