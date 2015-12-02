#!/bin/zsh -f
# Purpose: 
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-12-02

NAME="$0:t:r"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

INSTALL_TO='/Applications/Charles.app'

INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo '0'`

	# This returns just the version number 
LATEST_VERSION=`curl -sfL http://www.charlesproxy.com/latest.do`

autoload is-at-least

is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

if [ "$?" = "0" ]
then
	echo "$NAME: Up-To-Date (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"
	exit 0
fi

echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"

URL="https://www.charlesproxy.com/assets/release/$LATEST_VERSION/charles-proxy-$LATEST_VERSION.dmg"

FILENAME="$HOME/Downloads/Charles-$LATEST_VERSION.dmg"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0


if [ -e "$INSTALL_TO" ]
then
		# Quit app, if running
	pgrep -xq "Charles" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "Charles" to quit'

		# move installed version to trash 
	mv -vf "$INSTALL_TO" "$HOME/.Trash/Charles.$INSTALLED_VERSION.app"
fi

	# Note that this will automatically accept the EULA without reading it
	# just like you would have done :-) 
MNTPNT=$(echo -n "Y" | hdid -plist "$FILENAME" 2>/dev/null | fgrep '/Volumes/' | sed 's#</string>##g ; s#.*<string>##g')

if [[ "$MNTPNT" == "" ]]
then
	echo "$NAME: MNTPNT is empty"
	exit 1
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

	# Extract from the .zip file and install (this will leave the .zip file in place)
ditto --noqtn -v "$MNTPNT/Charles.app" "$INSTALL_TO"

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: Installation of $INSTALL_TO was successful."
	
	[[ "$LAUNCH" == "yes" ]] && open -a "$INSTALL_TO"
	
else
	echo "$NAME: Installation of $INSTALL_TO failed (\$EXIT = $EXIT)\nThe downloaded file can be found at $FILENAME."
fi

diskutil eject "$MNTPNT"


exit 0
#EOF
