#!/bin/zsh -f
# Purpose: Download and install the latest version of Keyboard Maestro
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-02

NAME="$0:t:r"

INSTALL_TO='/Applications/Keyboard Maestro.app'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

LAUNCH_APP=""

LAUNCH_ENGINE="yes"

LATEST_VERSION=$(curl -sfL http://www.keyboardmaestro.com/main/ | fgrep -i '<title>' | tr -dc '[0-9]\.')

[[ "$LATEST_VERSION" == "" ]] && echo "$NAME: LATEST_VERSION is empty." && exit 1

LATEST_VERSION_SQUISHED=`echo $LATEST_VERSION | tr -dc '[0-9]'`

URL="https://files.stairways.com/keyboardmaestro-$LATEST_VERSION_SQUISHED.zip"

# INFO=($(curl -sL 'http://files.stairways.com' \
# 		| egrep -i 'keyboardmaestro.*\.zip' \
# 		| head -1 \
# 		| sed 's#<li><a href="##g; s#">Keyboard Maestro # #g; s#</a></li>##g'))
#
# LATEST_VERSION="$INFO[2]"
#
# URL="http://files.stairways.com/$INFO[1]"
#
#
	# If any of these are blank, we should not continue
# if [ "$INFO" = "" -o "$LATEST_VERSION" = "" -o "$URL" = "" ]
# then
# 	echo "$NAME: Error: bad data received:
# 	INFO: $INFO
# 	LATEST_VERSION: $LATEST_VERSION
# 	URL: $URL
# 	"
#
# 	exit 1
# fi

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

FILENAME="$HOME/Downloads/$URL:t"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

ENGINE_SEPARATE=''

if [ -e "$INSTALL_TO" ]
then

	pgrep -q 'Keyboard Maestro Engine' \
	&& LAUNCH_ENGINE='yes' \
	&& osascript -e 'tell application "Keyboard Maestro Engine" to quit'

	pgrep -q 'Keyboard Maestro' \
	&& LAUNCH_APP='yes' \
	&& osascript -e 'tell application "Keyboard Maestro" to quit'

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/Keyboard Maestro.$INSTALLED_VERSION.app"

	ENGINE_SEPARATE="/Applications/Keyboard Maestro Engine.app"

	if [[ -d "$ENGINE_SEPARATE" ]]
	then
		mv -vf "$ENGINE_SEPARATE" "$HOME/.Trash/Keyboard Maestro Engine.$INSTALLED_VERSION.app"
	fi
fi



echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

ditto --noqtn -xk "$FILENAME" "$INSTALL_TO:h/"

EXIT="$?"

if [ "$EXIT" = "0" ]
then

	echo "$NAME: Installation successful"

		# move the engine to the /Applications/ folder if it was there before
	if [[ "$ENGINE_SEPARATE" != "" ]]
	then
		mv -vf "$INSTALL_TO/Contents/MacOS/Keyboard Maestro Engine.app" "$INSTALL_TO:h/"

	fi

	# Rename the downloaded file based on the version number we leanred
	# Note: CFBundleVersion is the same so we don't include it
	NEW_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString`

	[[ "$NEW_VERSION" != "" ]] &&
	mv -fv "$FILENAME" "$FILENAME:h/KeyboardMaestro-$NEW_VERSION.zip"

else
	echo "$NAME: ditto failed (\$EXIT = $EXIT)"

	exit 1
fi

[[ "$LAUNCH_ENGINE" == "yes" ]]	&& open -b com.stairways.keyboardmaestro.engine 2>&1

[[ "$LAUNCH_APP" == "yes" ]] 		&& open -b com.stairways.keyboardmaestro.editor 2>&1

exit 0
#EOF
