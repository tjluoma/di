#!/bin/zsh -f
# Purpose: Download and install the latest version of BBEdit
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-10-28

NAME="$0:t:r"

INSTALL_TO='/Applications/BBEdit.app'

if [ -e "/Users/luomat/.path" ]
then
	source "/Users/luomat/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

# INFO=($(curl -sfL 'https://versioncheck.barebones.com/BBEdit.cgi' \
# | egrep -A1 '<key>SUFeedEntryShortVersionString</key>|<key>SUFeedEntryUpdateURL</key>' \
# | fgrep '<string>' \
# | tail -2 \
# | sed 's#.*<string>##g; s#</string>.*##g'))
#
# LATEST_VERSION="$INFO[1]"
#
# URL="$INFO[2]"

################################################################################################################
## 2016-02-04 - the URL seems to lead to a 'BBEdit_11.5.cpgz' file but I want the dmg
## so I look for the DMG and then extract the version number from the filename

	## 2018-07-17 Found new URL via find_appcast
	#  XML_FEED='https://versioncheck.barebones.com/BBEdit.cgi'
XML_FEED='https://versioncheck.barebones.com/BBEdit.xml'

URL=$(curl -sfL "$XML_FEED" \
	| egrep '\.dmg</string>$' \
	| tail -1 \
	| sed 's#.*<string>##g; s#</string>##g')

LATEST_VERSION=`echo "$URL:t:r" | tr -dc '[0-9].'`

	# If any of these are blank, we should not continue
if [ "$LATEST_VERSION" = "" -o "$URL" = "" ]
then
	echo "$NAME: Error: bad data received:
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	"

	exit 1
fi

##
################################################################################################################

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

FILENAME="$HOME/Downloads/BBEdit-$LATEST_VERSION.dmg"

echo "$NAME: Downloading $URL to $FILENAME"

 curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

if [ -e "$INSTALL_TO" ]
then

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/BBEdit.$INSTALLED_VERSION.app"
fi


MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
		| fgrep -A 1 '<key>mount-point</key>' \
		| tail -1 \
		| sed 's#</string>.*##g ; s#.*<string>##g')

if [[ "$MNTPNT" == "" ]]
then
	echo "$NAME: MNTPNT is empty"
	exit 1
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

ditto --noqtn "$MNTPNT/$INSTALL_TO:t" "$INSTALL_TO"

EXIT="$?"

if [ "$EXIT" = "0" ]
then

	echo "$NAME: Successfully installed $INSTALL_TO"

else
	echo "$NAME: 'ditto' failed (\$EXIT = $EXIT)"

	exit 1
fi


diskutil eject "$MNTPNT"


exit 0
#EOF
