#!/bin/zsh -f
# Purpose: Download and install Mailplane.app (v3) note that v4 is now available
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2015-02-02

NAME="$0:t:r"

INSTALL_TO='/Applications/Mailplane 3.app'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

URL=$(curl -sfL --head http://update.mailplaneapp.com/mailplane_3.php \
	| awk -F': ' '/^Location/{print $NF}' \
	| tail -1 \
	| tr -d '[:cntrl:]')

[[ "$URL" == "" ]] && echo "$NAME: Empty URL" && exit 1

LATEST_VERSION=`echo "$URL:t:r" | sed 's#Mailplane_3_##g'`

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleVersion 2>/dev/null || echo '0'`

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

FILENAME="$HOME/Downloads/MailPlane-3-${LATEST_VERSION}.tbz"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download failed (EXIT = $EXIT)" && exit 0

if [[ -e "$INSTALL_TO" ]]
then
		# Quit app, if running
	pgrep -xq "MailPlane 3" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "MailPlane 3" to quit'

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/MailPlane 3.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h"

tar -x -C "$INSTALL_TO:h" -j -f "$FILENAME"

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
