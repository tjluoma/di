#!/bin/zsh -f
# Purpose: get the latest version of Zoom
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2019-06-21

NAME="$0:t:r"

if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
else
	PATH='/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin'
fi

	# This is where the app will be installed or updated.
if [[ -d '/Volumes/Applications' ]]
then
	INSTALL_TO='/Volumes/Applications/zoom.us.app'
else
	INSTALL_TO='/Applications/zoom.us.app'
fi

RELEASE_NOTES_URL='https://support.zoom.us/hc/en-us/articles/201361963-New-Updates-for-Mac-OS'

	# this assumes that 'https://zoom.us/client/latest/Zoom.pkg' won't change
URL=$(curl -sfLS --head https://zoom.us/client/latest/Zoom.pkg | awk -F' |\r' '/^.ocation:/{print $2}' | tail -1)

LATEST_VERSION=$(echo "${URL}" | awk -F'/' '/http/{print $5}')

	# If any of these are blank, we cannot continue
if [ "$URL" = "" -o "$LATEST_VERSION" = "" ]
then
	echo "$NAME: Error: bad data received:
	LATEST_VERSION: $LATEST_VERSION
	URL: $URL
	"

	exit 1
fi


if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info" CFBundleVersion)

	autoload is-at-least

	is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"

	VERSION_COMPARE="$?"

	if [ "$VERSION_COMPARE" = "0" ]
	then
		echo "$NAME: Up-To-Date ($INSTALLED_VERSION)"
		exit 0
	fi

	echo "$NAME: Outdated: $INSTALLED_VERSION vs $LATEST_VERSION"

	FIRST_INSTALL='no'

else

	FIRST_INSTALL='yes'
fi

FILENAME="$HOME/Downloads/Zoom-${LATEST_VERSION}.pkg"

if (( $+commands[lynx] ))
then

	(curl -sfLS "$RELEASE_NOTES_URL" \
		| sed '1,/<h2>Current Release<\/h2>/d; /<h2>Previous Releases<\/h2>/,$d' \
		| fgrep -v '<hr class="style-two" />' \
		| lynx -dump -nomargins -width='1000' -assume_charset=UTF-8 -pseudo_inlines -stdin ;
		echo "\nSource: $RELEASE_NOTES_URL\nURL: $URL" ) \
	| tee "$FILENAME:r.txt"

fi

echo "$NAME: Downloading '$URL' to '$FILENAME':"

curl --continue-at - --fail --location --output "$FILENAME" "$URL"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0

(cd "$FILENAME:h" ; echo "\n\nLocal sha256:" ; shasum -a 256 -p "$FILENAME:t" ) >>| "$FILENAME:r.txt"

if (( $+commands[pkginstall.sh] ))
then

	pkginstall.sh "$FILENAME"

else
		# fall back to either `sudo installer` or macOS's installer app
	sudo /usr/sbin/installer -verbose -pkg "$FILENAME" -dumplog -target / -lang en 2>&1 \
	|| open -b com.apple.installer "$FILENAME"

fi

	## the app will automatically start when installed/updated. I don't usually want that, so
	## this will quit it. If you do want that, remove or comment-out the next line.
osascript -e 'tell application "zoom.us" to quit' 2>/dev/null || true

exit 0
#EOF
