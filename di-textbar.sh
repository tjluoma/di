#!/bin/zsh -f
# Purpose: Download and install latest version of TextBar
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2015-04-18

NAME="$0:t:r"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

	# Where is the XML sparkle feed
XML_URL='http://www.richsomerfield.com/apps/textbar/sparkle_textbar.xml'

	# The most recent version in the XML feed
LATEST_VERSION=`curl -sL "$XML_URL" \
| tr ' ' '\012' \
| fgrep 'sparkle:version="' \
| head -1 \
| tr -dc '[0-9].'`

	# The URL of the actual latest zip file to download
DOWNLOAD_ACTUAL=`curl -sL "$XML_URL" \
| tr '"' '\012' \
| egrep "http.*\.zip" \
| head -1`

	# The size of the zip file in the XML feed
REMOTE_SIZE=`curl -sfL --head "$DOWNLOAD_ACTUAL" \
| awk -F' ' '/^Content-Length/{print $NF}' \
| tr -dc '[0-9]'`

	# Where should the app be installed to
INSTALL_TO="/Applications/TextBar.app"

	# Get the currently install version number, if any
	# if none, set to 0
INSTALLED_VERSION=`defaults read ${INSTALL_TO}/Contents/Info CFBundleShortVersionString 2>/dev/null || echo 0`

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

	# where do we want to keep the .zip file we are downloading
if [ -d "$HOME/Sites/iusethis.luo.ma/textbar" ]
then
	DIR="$HOME/Sites/iusethis.luo.ma/textbar"
elif [ -d "$HOME/BitTorrent Sync/iusethis.luo.ma/textbar" ]
then
	DIR="$HOME/BitTorrent Sync/iusethis.luo.ma/textbar"
else
	DIR="$HOME/Downloads"
fi

	# chdir to the appropriate dir
cd "$DIR"

	# Download the latest zip
echo "$NAME: Downloading $DOWNLOAD_ACTUAL to $PWD"
curl -fL --remote-name --progress-bar "$DOWNLOAD_ACTUAL"

	# Make sure the file size that we have matches what we should have
FILENAME="$HOME/Downloads/TextBar-$LATEST_VERSION.zip"

zmodload zsh/stat

SIZE=$(zstat -L +size "$FILENAME")

if [ "$SIZE" != "$REMOTE_SIZE" ]
then
	echo "$NAME: size mismatch Local: $SIZE vs Remote: $REMOTE_SIZE"
	exit 0
fi

	# Quit the app, if running, otherwise harmless
pkill -x TextBar

	# Move the old version to the trash, if there is one
	# put its version number in the filename in case we want to go back to it
[[ -d "$INSTALL_TO" ]] \
&& mv -vn "$INSTALL_TO" "$HOME/.Trash/TextBar.$INSTALLED_VERSION.app" 2>/dev/null

	# unzip the file we downloaded into /Applications/ aka the 'head' folder
	# of $INSTALL_TO

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h"
ditto --noqtn -xk "$FILENAME" "$INSTALL_TO:h/"

	# Launch the app without stealing focus
echo "$NAME: Launching TextBar"
open -g -a TextBar

exit 0
#
#EOF
