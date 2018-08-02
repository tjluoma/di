#!/bin/zsh -f
# Purpose: Download and install Alfred 2, or update it if already installed (note there is a separate script for Alfred 3)
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-11-10

NAME="$0:t:r"

INSTALL_TO='/Applications/Alfred 2.app'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

LAUNCH='no'

XML_FEED='https://cachefly.alfredapp.com/updater/info.plist'

INFO=($(curl -sfL "$XML_FEED" \
	| egrep -A1 '<key>version</key>|<key>build</key>|<key>location</key>' \
	| egrep '<string>|<integer>' \
	| head -3 \
	| awk -F'>|<' '//{print $3}'))

MAJOR_VERSION="$INFO[1]"
LATEST_VERSION="$INFO[2]"
URL="$INFO[3]"

	# If any of these are blank, we should not continue
if [ "$INFO" = "" -o "$LATEST_VERSION" = "" -o "$URL" = "" -o "$MAJOR_VERSION" = "" ]
then
	echo "$NAME: Error: bad data received:
	INFO: $INFO
	LATEST_VERSION: $LATEST_VERSION
	MAJOR_VERSION: $MAJOR_VERSION
	URL: $URL
	"

	exit 1
fi

FILENAME="$HOME/Downloads/Alfred-${MAJOR_VERSION}-${LATEST_VERSION}.zip"

if [[ -e "$INSTALL_TO" ]]
then

		# Note that we are using the Build Number/CFBundleVersion for Alfred,
		# because that changes more often than the CFBundleShortVersionString
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

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at - --progress-bar --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

if [ -e "$INSTALL_TO" ]
then
		# Quit app, if running
	pgrep -xq "Alfred 2" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "Alfred 2" to quit'

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/Alfred 2.$INSTALLED_VERSION.app"
fi

echo "$NAME: Installing $FILENAME to $INSTALL_TO:h/"

ditto --noqtn -xk "$FILENAME" "$INSTALL_TO:h/"

EXIT="$?"

if [ "$EXIT" = "0" ]
then

	echo "$NAME: Installation of $INSTALL_TO successful"

else
	echo "$NAME: 'ditto' failed (\$EXIT = $EXIT)"

	exit 1
fi

[[ "$LAUNCH" = "yes" ]] && open -a "$INSTALL_TO"

exit 0
#EOF
