#!/bin/zsh -f
# Purpose:
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-04

NAME="$0:t:r"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

INSTALL_TO='/Applications/Fission.app'

INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo '0'`

INSTALLED_VERSION_RAW=`echo "$INSTALLED_VERSION" | tr -dc '[0-9]'`

OS=`sw_vers -productVersion | tr -dc '[0-9]'`

XML="http://rogueamoeba.net/ping/versionCheck.cgi?format=sparkle&bundleid=com.rogueamoeba.Fission&system=${OS}&platform=osx&arch=x86_64&version=${INSTALLED_VERSION_RAW}8000"

LATEST_VERSION=`curl -sfL "$XML" | awk -F'"' '/sparkle:version=/{print $2}'`

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

	# Try to parse the download URL from the download page
URL=`curl -sfL 'http://www.rogueamoeba.com/fission/download.php' | tr '"' '\012' | egrep '\.(zip|dmg)$' | head -1`

	# if we didn't get anything, fall back to this
[[ "$URL" == "" ]] && URL='http://rogueamoeba.com/fission/download/Fission.zip'

FILENAME="$HOME/Downloads/Fission-$LATEST_VERSION.zip"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

if [ -e "$INSTALL_TO" ]
then

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/Fission.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

ditto --noqtn -xk "$FILENAME" "$INSTALL_TO:h/"

exit 0
#EOF
