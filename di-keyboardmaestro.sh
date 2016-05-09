#!/bin/zsh -f
# Purpose:
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-02

# @TODO - examine with Charles proxy to see if you can get a better update URL?

NAME="$0:t:r"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

LAUNCH_APP=""

LAUNCH_ENGINE=""

INSTALL_TO='/Applications/Keyboard Maestro.app'

INFO=($(curl -sL 'http://files.stairways.com' | egrep -i 'keyboardmaestro.*\.zip' | head -1 | sed 's#<li><a href="##g; s#">Keyboard Maestro # #g; s#</a></li>##g'))

LATEST_VERSION="$INFO[2]"

URL="http://files.stairways.com/$INFO[1]"

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

FILENAME="$HOME/Downloads/$INFO[1]"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

if [ -e "$INSTALL_TO" ]
then

	pgrep -q 'Keyboard Maestro Engine' \
	&& LAUNCH_ENGINE='yes' \
	&& osascript -e 'tell application "Keyboard Maestro Engine" to quit'

	pgrep -q 'Keyboard Maestro' \
	&& LAUNCH_APP='yes' \
	&& osascript -e 'tell application "Keyboard Maestro" to quit'

fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

ditto --noqtn -xk "$FILENAME" "$INSTALL_TO:h/"

[[ "$LAUNCH_ENGINE" == "yes" ]] && open "$INSTALL_TO/Contents/Resources/Keyboard Maestro Engine.app"

[[ "$LAUNCH_ENGINE" == "yes" ]] && open "$INSTALL_TO"

exit 0
#EOF
