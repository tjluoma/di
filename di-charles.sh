#!/usr/bin/env zsh -f
# Purpose: Download and install Charles proxy v3 (if installed) or 4 from <https://www.charlesproxy.com>
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2015-12-02

NAME="$0:t:r"

INSTALL_TO='/Applications/Charles.app'

HOMEPAGE="https://www.charlesproxy.com"

DOWNLOAD_PAGE="https://www.charlesproxy.com/download/"

SUMMARY="Charles is an HTTP proxy / HTTP monitor / Reverse Proxy that enables a developer to view all of the HTTP and SSL / HTTPS traffic between their machine and the Internet. This includes requests, responses and the HTTP headers (which contain the cookies and caching information)."

RELEASE_NOTES_URL='https://www.charlesproxy.com/documentation/version-history/'

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

function use_charles_v3 {

	URL="https://www.charlesproxy.com/assets/release/3.12.3/charles-proxy-3.12.3.dmg"
	LATEST_VERSION=`echo "$URL:t:r" | tr -dc '[0-9]\.'`
	ASTERISK='(Note that version 4 is now available.)'
}

	# versions 3 and 4 are both compatible with macOS 10.7 - 10.13

if [[ -e "$INSTALL_TO" ]]
then
		# if v3 is installed, check that. Otherwise, use v4
	MAJOR_VERSION=$(defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString | cut -d. -f1)

	if [[ "$MAJOR_VERSION" == "3" ]]
	then
		use_charles_v3
	fi
else
	if [ "$1" = "--use3" -o "$1" = "-3" ]
	then
		use_charles_v3
	fi
fi

if [[ "$LATEST_VERSION" == "" ]]
then

		# This returns just the version number
	LATEST_VERSION=`curl -sfL http://www.charlesproxy.com/latest.do`
	URL="https://www.charlesproxy.com/assets/release/$LATEST_VERSION/charles-proxy-$LATEST_VERSION.dmg"
fi

if [[ -e "$INSTALL_TO" ]]
then
	INSTALLED_VERSION=`defaults read "$INSTALL_TO/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo '0'`

	if [[ "$LATEST_VERSION" == "$INSTALLED_VERSION" ]]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION) $ASTERISK"
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

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-$LATEST_VERSION.dmg"

if (( $+commands[lynx] ))
then

	(curl -sfLS $RELEASE_NOTES_URL \
	| awk '/<h4>/{i++}i==1' \
	| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin ;
	echo "\nSource: <$RELEASE_NOTES_URL>") \
	| tee "$FILENAME:r.txt"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

if [ -e "$INSTALL_TO" ]
then
		# Quit app, if running
	pgrep -xq "Charles" \
	&& LAUNCH='yes' \
	&& osascript -e 'tell application "Charles" to quit'

		# move installed version to trash
	mv -vf "$INSTALL_TO" "$HOME/.Trash/Charles.$INSTALLED_VERSION.app"
fi

echo "$NAME: Accepting EULA and mounting '$FILENAME':"

	# Note that this will automatically accept the EULA without reading it
	# just like you would have done :-)
MNTPNT=$(echo -n "Y" | hdid -plist "$FILENAME" 2>/dev/null | fgrep '/Volumes/' | sed 's#</string>##g ; s#.*<string>##g')

if [[ "$MNTPNT" == "" ]]
then
	echo "$NAME: MNTPNT is empty"
	exit 1
fi

echo "$NAME: Installing '$MNTPNT/Charles.app' to '$INSTALL_TO:h/':"

	# Extract from the .zip file and install (this will leave the .zip file in place)
ditto --noqtn -v "$MNTPNT/Charles.app" "$INSTALL_TO"

EXIT="$?"

if [ "$EXIT" = "0" ]
then
	echo "$NAME: Installation of $INSTALL_TO was successful."

	[[ "$LAUNCH" == "yes" ]] && open -a "$INSTALL_TO"

else
	echo "$NAME: Installation of $INSTALL_TO failed (\$EXIT = $EXIT)\nThe downloaded file can be found at $FILENAME."
fi

diskutil eject "$MNTPNT"

exit 0
#EOF
