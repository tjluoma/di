#!/bin/zsh -f
# Purpose: download and install latest version of DevonThink Pro Office
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2015-05-19

NAME="$0:t:r"

INSTALL_TO='/Applications/DEVONthink Pro.app'

XML_FEED='https://www.devontechnologies.com/Sparkle/DEVONthinkProOffice2.xml'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

INFO=($(curl -sfL "$XML_FEED" \
		| tr -s ' ' '\012' \
		| egrep 'sparkle:version=|url=' \
		| tail -2 \
		| sort \
		| awk -F'"' '/^/{print $2}'))

	# "Sparkle" will always come before "url" because of "sort"
LATEST_VERSION="$INFO[1]"

URL="$INFO[2]"

if [ "$INFO" = "" -o "$LATEST_VERSION" = "" -o "$URL" = "" ]
then
	echo "$NAME: Error: bad data received:
	INFO: $INFO
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	"

	exit 1
fi


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

if (( $+commands[lynx] ))
then

	RELEASE_NOTES_URL=$(curl -sfL "$XML_FEED" \
	| fgrep -i '<description>' \
	| tail -1 \
	| sed 's#.*<description>##g; s#&amp;.*</description>.*#\&format=html#g')

	echo -n "$NAME: Release Notes for $INSTALL_TO:t:r version $LATEST_VERSION:"

	lynx -dump -nomargins -width=10000 -assume_charset=UTF-8 -pseudo_inlines "$RELEASE_NOTES_URL"

	echo "\nSource: <$RELEASE_NOTES_URL>"

fi

FILENAME="$HOME/Downloads/DevonThinkProOffice-${LATEST_VERSION}.zip"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download failed (EXIT = $EXIT)" && exit 0

if [[ -e "$INSTALL_TO" ]]
then
		## Quit app, if running
		# 	pgrep -xq "DEVONthink Pro" \
		# 	&& LAUNCH='yes' \
		# 	&& osascript -e 'tell application "DEVONthink Pro" to quit'

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/DEVONthink Pro.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

	# Extract from the .zip file and install (this will leave the .zip file in place)
ditto --noqtn -xk "$FILENAME" "$INSTALL_TO:h/"

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: Installation of $INSTALL_TO was successful."

	[[ "$LAUNCH" == "yes" ]] && open -a "$INSTALL_TO"

else
	echo "$NAME: Installation of $INSTALL_TO failed (ditto \$EXIT = $EXIT)\nThe downloaded file can be found at $FILENAME."

	exit 1
fi

exit 0
#
#EOF
