#!/bin/zsh -f
# Purpose:
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2015-10-26

NAME="$0:t:r"

INSTALL_TO='/Applications/Jettison.app'

INSTALLED_VERSION=`defaults read "${INSTALL_TO}/Contents/Info" CFBundleVersion 2>/dev/null || echo '2000'`

XML_FEED='http://www.stclairsoft.com/updates/Jettison.xml'

INFO=($(curl -sfL "$XML_FEED" \
| tr -s ' ' '\012' \
| egrep 'sparkle:shortVersionString|sparkle:version=|url=' \
| head -3 \
| sort \
| awk -F'"' '/^/{print $2}'))

	# "Sparkle" will always come before "url" because of "sort"
READABLE_VERSION="$INFO[1]"
LATEST_VERSION="$INFO[2]"
URL="$INFO[3]"

	# If any of these are blank, we should not continue
if [ "$INFO" = "" -o "$LATEST_VERSION" = "" -o "$URL" = "" ]
then
	echo "$NAME: Error: bad data received:\nINFO: $INFO"
	exit 0
fi

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


FILENAME="$HOME/Downloads/Jettison-${READABLE_VERSION}-${LATEST_VERSION}.dmg"

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

	REG_FILE="$HOME/dotfiles/licenses/jettison/com.stclairsoft.Jettison.plist"

	PREF_FILE"$HOME/Library/Preferences/com.stclairsoft.Jettison.plist"

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
