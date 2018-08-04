#!/bin/zsh -f
# Purpose: Download and install nvALT
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-19

NAME="$0:t:r"

INSTALL_TO='/Applications/nvALT.app'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

# this is old
# XML_FEED='http://abyss.designheresy.com/nvalt2/nvalt2main.xml'

# This is new, current as of 2018-07-10 at least
XML_FEED='https://updates.designheresy.com/nvalt/updates.xml'


INFO=($(curl -sfL "$XML_FEED" \
		| tr -s ' ' '\012' \
		| egrep 'sparkle:shortVersionString|sparkle:version=|url=' \
		| head -3 \
		| sort \
		| awk -F'"' '/^/{print $2}'))

	# "Sparkle" will always come before "url" because of "sort"
LATEST_VERSION="$INFO[1]"
LATEST_BUILD="$INFO[2]"
URL="$INFO[3]"


	# If any of these are blank, we should not continue
if [ "$INFO" = "" -o "$LATEST_BUILD" = "" -o "$URL" = "" -o "$LATEST_VERSION" = "" ]
then
	echo "$NAME: Error: bad data received:
	INFO: $INFO
	LATEST_VERSION: $LATEST_VERSION
	LATEST_BUILD: $LATEST_BUILD
	URL: $URL
	"

	exit 1
fi

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleVersion 2>/dev/null`

	if [[ "$LATEST_BUILD" == "$INSTALLED_VERSION" ]]
	then
		echo "$NAME: Up-To-Date ($LATEST_VERSION/$INSTALLED_VERSION)"
		exit 0
	fi

	autoload is-at-least

	is-at-least "$LATEST_BUILD" "$INSTALLED_VERSION"

	if [ "$?" = "0" ]
	then
		echo "$NAME: Installed version ($INSTALLED_VERSION) is ahead of official version $LATEST_BUILD"
		exit 0
	fi

	echo "$NAME: Outdated (Installed = $INSTALLED_VERSION vs Latest = $LATEST_BUILD)"

fi

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}-${LATEST_BUILD}.zip"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download failed (EXIT = $EXIT)" && exit 0

if [ -e "$INSTALL_TO" ]
then
		# Quit app, if running
	pgrep -xq "$INSTALL_TO:t:r" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "$INSTALL_TO:t:r" to quit'

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/$INSTALL_TO:t:r.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

	# Extract from the .zip file and install (this will leave the .zip file in place)
ditto --noqtn -xk "$FILENAME" "$INSTALL_TO:h/"

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: Installation of $INSTALL_TO was successful."

	[[ "$LAUNCH" == "yes" ]] && open -g -a "$INSTALL_TO"

else
	echo "$NAME: Installation of $INSTALL_TO failed (\$EXIT = $EXIT)\nThe downloaded file can be found at $FILENAME."
fi


exit 0
#
#EOF
