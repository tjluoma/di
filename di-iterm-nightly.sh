#!/bin/zsh -f
# Purpose: Download and install the latest _nightly_ version of iTerm 2
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2014-10-03
# Updated: 2018-07-03

NAME="$0:t:r"

INSTALL_TO='/Applications/iTerm.app'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

#    SUFeedURLForFinal = "https://iterm2.com/appcasts/final.xml";
#    SUFeedURLForTesting = "https://iterm2.com/appcasts/nightly.xml";

XML_FEED='https://iterm2.com/appcasts/nightly.xml'

INFO=($(curl -sfL "$XML_FEED" \
		| tr -s ' ' '\012' \
		| egrep 'sparkle:version=|url=' \
		| head -2 \
		| sort \
		| awk -F'"' '/^/{print $2}'))

	# "Sparkle" will always come before "url" because of "sort"
LATEST_VERSION="$INFO[1]"

URL="$INFO[2]"

	# If any of these are blank, we should not continue
if [ "$INFO" = "" -o "$LATEST_VERSION" = "" -o "$URL" = "" ]
then
	echo "$NAME: Error: bad data received:
	INFO: $INFO
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	"

	exit 1
fi

	# Remote '-nightly' from version string from XML feed
	# because it is not used in CFBundleShortVersionString
LATEST_VERSION=`echo "$LATEST_VERSION" | sed 's#-nightly##g'`

if [ -e "$INSTALL_TO" ]
then
		# if the app is installed, check to see what version we are running
	INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null | tr -dc '[0-9].'`

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

FILENAME="$HOME/Downloads/iTerm-${LATEST_VERSION}.zip"

echo "$NAME: Downloading $URL to $FILENAME"

 curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

	# 2016-03-24 - for some reason the file is zero bytes
[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

if [ -e "$INSTALL_TO" ]
then
		# DON'T QUIT if running, or we might terminate ourselves!
		# Just move to the trash. The app will still work. Next time it's launched
		# it will launch new version

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/iTerm.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

	# Extract from the .zip file and install (this will leave the .zip file in place)
ditto --noqtn -xk "$FILENAME" "$INSTALL_TO:h/"

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: Installation of $INSTALL_TO was successful."

	(( $+commands[growlnotify] )) \
	&& pgrep -xq Growl \
	&& growlnotify --sticky --appIcon "iTerm" --identifier "$NAME" --message "Updated iTerm to $LATEST_VERSION" --title "$NAME"

		# No reason to keep the nightly download, it's not like we'd want to use it again in days/months
	mv -vf "$FILENAME" "$HOME/.Trash/"
else
	echo "$NAME: Installation of $INSTALL_TO failed (ditto \$EXIT = $EXIT)\nThe downloaded file can be found at $FILENAME."

	exit 1
fi

exit 0

#
#EOF
