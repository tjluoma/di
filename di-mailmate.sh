#!/bin/zsh -f
# Purpose: Download and install the latest version of MailMate
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-01

NAME="$0:t:r"

INSTALL_TO='/Applications/MailMate.app'

if [ -e "/Users/luomat/.path" ]
then
	source "/Users/luomat/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

LAUNCH='no'

## Use this for regular releases
# XML_FEED='http://updates.mailmate-app.com/'

## Use this for betas
XML_FEED='http://updates.mailmate-app.com/beta'

INFO=($(curl -sfL "$XML_FEED" | awk '{print $4" " $7}' | tr -d "'|;"))

URL="$INFO[1]"

LATEST_VERSION="$INFO[2]"

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

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=`defaults read $INSTALL_TO/Contents/Info CFBundleVersion 2>/dev/null || echo '0'`

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

if (is-growl-running-and-unpaused.sh)
then

	growlnotify \
		--sticky \
		--appIcon "$INSTALL_TO:t:r" \
		--identifier "$NAME" \
		--message "Updating to $LATEST_VERSION" \
		--title "$NAME"
fi

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-${LATEST_VERSION}.tbz"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

if [ -e "$INSTALL_TO" ]
then
		pgrep -x -q MailMate \
		&& LAUNCH='yes' \
		&& osascript -e 'tell application "MailMate" to quit'

		mv "$INSTALL_TO" "$HOME/.Trash/MailMate.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h"

tar -C "$INSTALL_TO:h" -j -x -f "$FILENAME"

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: Installation of $INSTALL_TO was successful."

	if (is-growl-running-and-unpaused.sh)
	then

		growlnotify \
			--appIcon "$INSTALL_TO:t:r" \
			--identifier "$NAME" \
			--message "Update Complete! ($LATEST_VERSION)" \
			--title "$NAME"
	fi

	[[ "$LAUNCH" == "yes" ]] && open -a "$INSTALL_TO"

else
	echo "$NAME: Installation of $INSTALL_TO failed (\$EXIT = $EXIT)\nThe downloaded file can be found at $FILENAME."
fi

exit 0
#EOF
