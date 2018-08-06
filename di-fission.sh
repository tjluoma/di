#!/bin/zsh -f
# Purpose: Download and install the latest version of Fission
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-04

NAME="$0:t:r"

INSTALL_TO='/Applications/Fission.app'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

# INSTALLED_VERSION_RAW=`echo "$INSTALLED_VERSION" | tr -dc '[0-9]'`
#
# OS=`sw_vers -productVersion | tr -dc '[0-9]'`
#
# XML="http://rogueamoeba.net/ping/versionCheck.cgi?format=sparkle&bundleid=com.rogueamoeba.Fission&system=${OS}&platform=osx&arch=x86_64&version=${INSTALLED_VERSION_RAW}8000"
#
# LATEST_VERSION=`curl -sfL "$XML" | awk -F'"' '/sparkle:version=/{print $2}'`

## Cask uses 'https://rogueamoeba.com/fission/releasenotes.php'
## This seems to pull the version number out quite well:
# 	curl -sfL 'https://rogueamoeba.com/fission/releasenotes.php' | egrep -i '<h1>.*</h1>' | head -1 | sed 's#.*<h1>Fission ##g; s#</h1>##g'

LATEST_VERSION=$(curl -sfL 'https://rogueamoeba.com/fission/releasenotes.php' \
				| egrep -i '<h1>.*</h1>' \
				| head -1 \
				| sed 's#.*<h1>Fission ##g; s#</h1>##g')

	# If this is blank, we should not continue
if [[ "$LATEST_VERSION" == "" ]]
then
	echo "$NAME: Error: bad data received:
	LATEST_VERSION: $LATEST_VERSION
	"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString`

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

	# Try to parse the download URL from the download page
URL=`curl -sfL 'http://www.rogueamoeba.com/fission/download.php' | tr '"' '\012' | egrep '\.(zip)$' | head -1`

	# if we didn't get anything, fall back to this
[[ "$URL" == "" ]] && URL='http://rogueamoeba.com/fission/download/Fission.zip'

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-$LATEST_VERSION.zip"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 1

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 1

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 1

UNZIP_TO=$(mktemp -d "${TMPDIR-/tmp/}${NAME}-XXXXXXXX")

echo "$NAME: Unzipping '$FILENAME' to '$UNZIP_TO':"

ditto -xk --noqtn "$FILENAME" "$UNZIP_TO"

EXIT="$?"

if [[ "$EXIT" == "0" ]]
then
	echo "$NAME: Unzip successful"
else
		# failed
	echo "$NAME failed (ditto -xkv '$FILENAME' '$UNZIP_TO')"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then
	echo "$NAME: Moving existing (old) \"$INSTALL_TO\" to \"$HOME/.Trash/\"."

	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"

	EXIT="$?"

	if [[ "$EXIT" != "0" ]]
	then

		echo "$NAME: failed to move existing $INSTALL_TO to $HOME/.Trash/"

		exit 1
	fi
fi

echo "$NAME: Moving new version of '$INSTALL_TO:t' (from '$UNZIP_TO') to '$INSTALL_TO'."

	# Move the file out of the folder
mv -vn "$UNZIP_TO/$INSTALL_TO:t" "$INSTALL_TO"

EXIT="$?"

if [[ "$EXIT" = "0" ]]
then

	echo "$NAME: Successfully installed '$UNZIP_TO/$INSTALL_TO:t' to '$INSTALL_TO'."

else
	echo "$NAME: Failed to move '$UNZIP_TO/$INSTALL_TO:t' to '$INSTALL_TO'."

	exit 1
fi

exit 0
#EOF
