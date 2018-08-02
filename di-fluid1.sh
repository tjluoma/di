#!/bin/zsh -f
# Purpose: Download and install the latest version of Fluid 1 (note version 2 is currently in beta)
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2018-07-17

NAME="$0:t:r"

INSTALL_TO='/Applications/Fluid.app'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

XML_FEED="https://fluidapp.com/appcast/fluid1.rss"

	## NOTE: sparkle:version can change even when sparkle:shortVersionString isn't

INFO=($(curl -sfL "$XML_FEED" \
		| tr '[:blank:]' '\012' \
		| egrep '^(sparkle:version="|sparkle:shortVersionString="|url="http.*\.zip")' \
		| head -3 \
		| sort ))

MAJOR_VERSION=$(echo "$INFO[1]" | tr -dc '[0-9]\.')

LATEST_VERSION=$(echo "$INFO[2]" | tr -dc '[0-9]\.')

URL=$(echo "$INFO[3]" | sed 's#url="##g; s#"##g')

if [ "$URL" = "" -o "$LATEST_VERSION" = "" -o "$MAJOR_VERSION" = "" ]
then
	echo "$NAME: Bad data from $XML_FEED"
	echo "
	INFO: $INFO
	MAJOR_VERSION: $MAJOR_VERSION
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleVersion)

	if [[ "$LATEST_VERSION" == "$INSTALLED_VERSION" ]]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION)"
		exit 0
	fi

	autoload is-at-least

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	if [ "$?" = "0" ]
	then
		echo "$NAME: Up-To-Date ($LATEST_VERSION)"
		exit 0
	fi

	echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_VERSION)"

fi

FILENAME="$HOME/Downloads/Fluid-${MAJOR_VERSION}-${LATEST_VERSION}.zip"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

if [[ -e "$INSTALL_TO" ]]
then
		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/Fluid.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

	# Extract from the .zip file and install (this will leave the .zip file in place)
ditto --noqtn -xk "$FILENAME" "$INSTALL_TO:h/"

EXIT="$?"

if [[ "$EXIT" == "0" ]]
then
	echo "$NAME: Installation of $INSTALL_TO was successful."
	exit 0
else
	echo "$NAME: Installation of $INSTALL_TO failed (\$EXIT = $EXIT)\nThe downloaded file can be found at $FILENAME."
	exit 1
fi


exit 0
#
#EOF
