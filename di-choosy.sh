#!/bin/zsh
# download and install Choosy
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-10-27

NAME="$0:t:r"

INSTALL_TO="$HOME/Library/PreferencePanes/Choosy.prefPane"

INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo 1.0.0`

INFO=($(curl -sfL 'http://www.choosyosx.com/sparkle/feed' | tr -s ' ' '\012' | egrep "sparkle:version=|url=" | head -2 | awk -F'"' '/^/{print $2}'))

URL="$INFO[2]"

LATEST_VERSION="$INFO[1]"

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

	# Where to save new download
FILENAME="$HOME/Downloads/Choosy-$LATEST_VERSION.zip"

	# Do the download
echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

# Move old version to trash
if [ -e "$INSTALL_TO" ]
then

	pgrep -qx Choosy && pkill Choosy

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"

	FIRST_INSTALL='no'
else
	FIRST_INSTALL='yes'
fi

	# Install

echo "$NAME: Installing $FILENAME to $INSTALL_TO"

ditto --noqtn -x -k  "$FILENAME" "$INSTALL_TO:h"

	# Remove quarantine info (there shouldn't be any, but just in case)
find "$INSTALL_TO" -print | xargs xattr -d com.apple.quarantine 2>/dev/null

### POST INSTALL

if (( $+commands[defaultbrowser] ))
then
	defaultbrowser -set choosy
else
	echo "$NAME: 'defaultbrowser' not found. Download from 'https://codeload.github.com/kerma/defaultbrowser/zip/master'."

	open 'https://codeload.github.com/kerma/defaultbrowser/zip/master'

fi

	# Launch Helper
echo "$NAME: Launching Choosy helper app"
open "$INSTALL_TO/Contents/Resources/Choosy.app/Contents/MacOS/Choosy"


	# If this is the first time it has been installed, open the preference pane so it can be configured
if [[ "$FIRST_INSTALL" == "yes" ]]
then
		# Launch App
	open "$INSTALL_TO"
fi


exit 0
#
#EOF
