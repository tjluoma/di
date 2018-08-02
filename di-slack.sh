#!/bin/zsh -f
# Purpose: Download the direct (not Mac App Store) version of Slack
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-12-17

NAME="$0:t:r"

INSTALL_TO='/Applications/Slack.app'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

	# ".ocation" takes care of Location: or location:
URL=$(curl -sfL --head "https://slack.com/ssb/download-osx" \
		| awk -F' ' '/^.ocation: /{print $2}' \
		| tail -1 \
		| tr -d '\r' )

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

fi

FILENAME="$HOME/Downloads/Slack-${LATEST_VERSION}.dmg"

echo "$NAME: Downloading >$URL< to >$FILENAME<"

 curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
		| fgrep -A 1 '<key>mount-point</key>' \
		| tail -1 \
		| sed 's#</string>.*##g ; s#.*<string>##g')

if [[ "$MNTPNT" == "" ]]
then
	echo "$NAME: MNTPNT is empty"
	exit 1
fi

echo "$NAME: Installing MNTPNT/Slack.app to $INSTALL_TO"

ditto --noqtn -v "$MNTPNT/Slack.app" "$INSTALL_TO"


EXIT="$?"

if [ "$EXIT" = "0" ]
then

	echo "$NAME: Installation success"

else
	echo "$NAME: ditto failed (\$EXIT = $EXIT)"

	exit 1
fi


diskutil eject "$MNTPNT"


exit 0


########################################################################################################################


## 2018-07-10 this URL is no longer valid
# XML_FEED="https://slack.com/ssb/download-osx-update"
#
# INFO=($(curl -sfL "$XML_FEED" \
# | tr -s ' ' '\012' \
# | egrep 'sparkle:shortVersionString=|url=' \
# | head -2 \
# | sort \
# | awk -F'"' '/^/{print $2}'))
#
# 	# "Sparkle" will always come before "url" because of "sort"
# LATEST_VERSION="$INFO[1]"
# URL="$INFO[2]"
#
# 	# If any of these are blank, we should not continue
# if [ "$INFO" = "" -o "$LATEST_VERSION" = "" -o "$URL" = "" ]
# then
# 	echo "$NAME: Error: bad data received:\nINFO: $INFO"
# 	exit 0
# fi


########################################################################################################################


## 2018-07-10 - the rest (below) is from when this was a .zip not a .dmg

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

	# Extract from the .zip file and install (this will leave the .zip file in place)
ditto --noqtn -xk "$FILENAME" "$INSTALL_TO:h/"

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: Installation of $INSTALL_TO was successful."

	[[ "$LAUNCH" == "yes" ]] && open -a "$INSTALL_TO"

else
	echo "$NAME: Installation of $INSTALL_TO failed (\$EXIT = $EXIT)\nThe downloaded file can be found at $FILENAME."
fi

########################################################################################################################


exit 0
#EOF
