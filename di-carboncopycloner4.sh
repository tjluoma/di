#!/bin/zsh -f
# Purpose: Download and install Carbon Copy Cloner, version 4 (note that version 5 is out)
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2016-05-02

NAME="$0:t:r"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

INSTALL_TO='/Applications/Carbon Copy Cloner 4.app'

	## NOTE: If nothing is installed, we need to pretend we have at least version 4
	## 			or else we will get version 3
INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo '4.0.0'`

	## NOTE: If nothing is installed, we need to pretend we have at least version 4000
	## 			or else we will get version 3
INSTALLED_BUNDLE_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleVersion 2>/dev/null || echo '4000'`

OS_MINOR=`sw_vers -productVersion | cut -d. -f 2`

OS_BUGFIX=`sw_vers -productVersion | cut -d. -f 3`

XML_FEED="https://bombich.com/software/updates/ccc.php?os_minor=$OS_MINOR&os_bugfix=$OS_BUGFIX&ccc=$INSTALLED_BUNDLE_VERSION&beta=0&locale=en"

# XML_FEED="https://bombich.com/software/updates/ccc.php?os_minor=$OS_MINOR&os_bugfix=$OS_BUGFIX&ccc=$INSTALLED_BUNDLE_VERSION&beta=0&locale=en"

## If you want betas, use this line
# XML_FEED="https://bombich.com/software/updates/ccc.php?os_minor=$OS_MINOR&os_bugfix=$OS_BUGFIX&ccc=$INSTALLED_BUNDLE_VERSION&beta=1&locale=en"

INFO=($(curl -sfL "$XML_FEED" \
| gunzip \
| tr -s ' ' '\012' \
| egrep 'sparkle:version|url="' \
| head -2 \
| sort \
| awk -F'"' '//{print $2}'))

# "Sparkle" will always come before "url" because of "sort"
LATEST_VERSION="$INFO[1]"
URL="$INFO[2]"

# If any of these are blank, we should not continue
if [ "$INFO" = "" -o "$LATEST_VERSION" = "" -o "$URL" = "" ]
then
	echo "$NAME: Error: bad data received from ${XML_FEED}\nINFO: $INFO"
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
	echo "$NAME: Up-To-Date (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"
	exit 0
fi

echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"

FILENAME="$HOME/Downloads/CarbonCopyCloner-${LATEST_VERSION}.zip"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

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
	# Note that we are renaming 'Carbon Copy Cloner.app' to 'Carbon Copy Cloner 4.app' as we do this
mv -vn "$UNZIP_TO/Carbon Copy Cloner.app" "$INSTALL_TO"

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
