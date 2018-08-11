#!/bin/zsh -f
# Purpose: Download and install the latest version of Jettison
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2015-10-26

NAME="$0:t:r"

INSTALL_TO='/Applications/Jettison.app'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

## 2018-07-17 -find_appcast gave us the URL of:
## 		https://www.stclairsoft.com/cgi-bin/sparkle.cgi?JT
## but the feed itself uses
## 		http://www.stclairsoft.com/updates/Jettison.xml
## so that's what I'm using

XML_FEED='http://www.stclairsoft.com/updates/Jettison.xml'

INFO=($(curl -sfL "$XML_FEED" \
		| tr -s ' ' '\012' \
		| egrep 'sparkle:shortVersionString|sparkle:version=|url=' \
		| head -3 \
		| sort \
		| awk -F'"' '/^/{print $2}'))

	# "Sparkle" will always come before "url" because of "sort"
LATEST_VERSION="$INFO[1]"
LATEST_BUILD="$INFO[2]"
URL="$INFO[3]"

	# If any of these are blank, we should not continue
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

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}-${LATEST_BUILD}.dmg"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

if [ -e "$INSTALL_TO" ]
then
		# Quit app, if running
	pgrep -xq "Jettison" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "Jettison" to quit'

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/Jettison.$INSTALLED_VERSION.app"
fi

MNTPNT=$(hdiutil attach -nobrowse -plist "$FILENAME" 2>/dev/null \
		| fgrep -A 1 '<key>mount-point</key>' \
		| tail -1 \
		| sed 's#</string>.*##g ; s#.*<string>##g')

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

ditto --noqtn "$MNTPNT/$INSTALL_TO:t" "$INSTALL_TO"

EXIT="$?"

if [ "$EXIT" = "0" ]
then

	echo "$NAME: Installation of $INSTALL_TO successful"

else
	echo "$NAME: ditto failed (\$EXIT = $EXIT)"

	exit 1
fi

[[ "$LAUNCH" == "yes" ]] && open -a "$INSTALL_TO"

if (( $+commands[unmount.sh] ))
then

	unmount.sh "$MNTPNT"
else
	diskutil eject "$MNTPNT"
fi

IS_REGISTERED=`defaults read com.stclairsoft.Jettison.plist registrationLicense 2>/dev/null`

if [[ "$IS_REGISTERED" == "" ]]
then

	REG_FILE="$HOME/Dropbox/dotfiles/licenses/jettison/com.stclairsoft.Jettison.plist"

	PREF_FILE="$HOME/Library/Preferences/com.stclairsoft.Jettison.plist"

	if [ -e "$REG_FILE" ]
	then
			if [ -e "$PREF_FILE" ]
			then

				echo "$NAME: $PREF_FILE already exists but does not have registration information."
				echo "	Do you want to overwrite that file with $REG_FILE? "

				command cp -iv "$REG_FILE" "$PREF_FILE"

			else
				# No Preferences file found so use the default one

				echo "$NAME: Copying $REG_FILE to $PREF_FILE"

				command cp -vn "$REG_FILE" "$PREF_FILE"
			fi

	else
		echo "$NAME: No REG_FILE found at $REG_FILE"
	fi

fi

exit 0
#
#EOF
