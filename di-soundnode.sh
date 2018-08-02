#!/bin/zsh -f
# Purpose: Download the latest version of Soundnode
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2016-06-02

NAME="$0:t:r"

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

INSTALL_TO="/Applications/Soundnode.app"

INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleVersion 2>/dev/null || echo '0'`

URL='http://www.soundnodeapp.com/downloads/mac/Soundnode.zip'

## 2018-08-02 - ok, for some reason there's a '7.0.0' tag_name, when all the rest are like this:
#     "tag_name": "0.6.5",
#     "tag_name": "0.6.4",
#     "tag_name": "0.6.3",
#     "tag_name": "0.6.2",
#     "tag_name": "0.6.1",
#     "tag_name": "0.6.0",
#     "tag_name": "0.5.9",
## So I'm just excluding that one for 'latest-version' checking purposes, because otherwise this will constantly run
## and replace itself with new versions that aren't really new. Not sure what else to do.

LATEST_VERSION=`curl -sfL https://api.github.com/repos/Soundnode/soundnode-app/releases \
				| fgrep tag_name \
				| fgrep -v '"tag_name": "7.0.0",' \
				| head -1 \
				| tr -dc '[0-9].'`

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

####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
#		Here’s the download section
#

FILENAME="$HOME/Downloads/Soundnode-$LATEST_VERSION.zip"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
#		Here’s the 'move the old version aside' section
#


if [ -e "$INSTALL_TO" ]
then
		# Quit app, if running
	pgrep -xq "Soundnode" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "Soundnode" to quit'

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/Soundnode.$INSTALLED_VERSION.app"
fi

####|####|####|####|####|####|####|####|####|####|####|####|####|####|####
#
#		Here’s the "install the new version" section
#



echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

	# Extract from the .zip file and install (this will leave the .zip file in place)
ditto --noqtn -xk "$FILENAME" "$INSTALL_TO:h/"

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: Installation of $INSTALL_TO was successful."

	[[ "$LAUNCH" == "yes" ]] && open -a "$INSTALL_TO"

else
	echo "$NAME: Installation of $INSTALL_TO failed (\$EXIT = $EXIT)\nThe downloaded file can be found at $FILENAME."
fi

exit 0
#EOF
