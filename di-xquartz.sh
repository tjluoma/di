#!/bin/zsh -f
# Purpose: Download and install (or update) Xquartz
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2014-06-10
#
# Updated 2018-07-17 - updated some of the code, removed the 'cache' feature since it is no longer needed,
# and update the XML_FEED to new URL thanks to the Homebrew Cask folks.

NAME="$0:t:r"

INSTALL_TO='/Applications/Utilities/XQuartz.app'

if [ -e "$HOME/.path" ]
then
	source "$HOME/.path"
else
	PATH=/usr/local/scripts:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
fi

zmodload zsh/datetime

function timestamp { strftime "%Y-%m-%d--%H.%M.%S" "$EPOCHSECONDS" }

########################################################################################################################

	# create a file (empty, if you like) at "$HOME/.config/di/xquartz-prefer-betas.txt"
	# if you want to install beta releases
if [[ -e "$HOME/.config/di/xquartz-prefer-betas.txt" ]]
then
	XML_FEED='https://www.xquartz.org/releases/sparkle/beta.xml'
	NAME="$NAME (beta releases)"
else
	XML_FEED='https://www.xquartz.org/releases/sparkle/release.xml'
fi

# sparkle:shortVersionString exists in the feed, but sparkle:version/CFBundleVersion is the important number to check

INFO=($(curl -sfL "$XML_FEED" \
	| tr -s ' ' '\012' \
	| egrep 'sparkle:version=|url=' \
	| head -2 \
	| awk -F'"' '/^/{print $2}'))

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

########################################################################################################################

zmodload zsh/datetime

TIME=$(strftime "%Y-%m-%d-at-%H.%M.%S" "$EPOCHSECONDS")

HOST=`hostname -s`
HOST="$HOST:l"

LOG="$HOME/Library/Logs/${NAME}.txt"

[[ -d "$LOG:h" ]] || mkdir -p "$LOG:h"
[[ -e "$LOG" ]]   || touch "$LOG"

function timestamp { strftime "%Y-%m-%d at %H:%M:%S" "$EPOCHSECONDS" }
function log { 	echo "$NAME [`timestamp`]: $@" | tee -a "$LOG" }

function msg {

	MSG="$@"

	log "$MSG"

	if (( $+commands[growlnotify] ))
	then
		growlnotify --appIcon "XQuartz" --identifier "install-update-xquartz" --message "$@" --title "Install/Update XQuartz"
	fi
}

function msgs {

	MSG="$@"

	log "$MSG"

	if (( $+commands[growlnotify] ))
	then
		growlnotify --sticky --appIcon "XQuartz" --identifier "install-update-xquartz" --message "$@" --title "Install/Update XQuartz"
	fi
}

########################################################################################################################

if [[ -e "$INSTALL_TO" ]]
then

	INSTALLED_VERSION=$(defaults read "${INSTALL_TO}/Contents/Info.plist" "CFBundleVersion" 2>/dev/null)

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

########################################################################################################################

if (( $+commands[lynx] ))
then

	RELEASE_NOTES_URL=$(curl -sfL "$XML_FEED" \
		| fgrep '<sparkle:releaseNotesLink>' \
		| head -1 \
		| sed 's#.*<sparkle:releaseNotesLink>##g ; s#</sparkle:releaseNotesLink>##g')

	echo "$NAME: Release Notes for $INSTALL_TO:t:r:"

	curl -sfL "${RELEASE_NOTES_URL}" \
	| sed '1,/launchctl/d; /id="credit"/,$d' \
	| lynx -dump -nomargins -width='10000' -assume_charset=UTF-8 -pseudo_inlines -stdin \
	| fgrep -v 'file:///var/folders/'

	echo "\nSource: <$RELEASE_NOTES_URL>"

fi

FILENAME="$HOME/Downloads/$INSTALL_TO:t:r-$LATEST_VERSION.dmg"

echo "$NAME: Downloading $URL to $FILENAME"

curl --continue-at -  --max-time 3600 --fail --location --referer ";auto" --progress-bar --output "${FILENAME}" "${URL}"

EXIT="$?"

	## exit 22 means 'the file was already fully downloaded'
[ "$EXIT" != "0" -a "$EXIT" != "22" ] && echo "$NAME: Download of $URL failed (EXIT = $EXIT)" && exit 0

[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && rm -f "$FILENAME" && exit 0


MNTPNT=$(echo -n "Y" \
	| hdid -plist "$FILENAME" 2>/dev/null \
	| fgrep -A 1 '<key>mount-point</key>' \
	| tail -1 \
	| sed 's#</string>.*##g ; s#.*<string>##g')

if [ "$MNTPNT" = "" ]
then
	msgs "MNTPNT is empty"
	exit 0
fi

PKG=`find "$MNTPNT" -maxdepth 1 -iname \*.pkg`

if [ "$PKG" = "" ]
then
	msgs "PKG is empty"
	exit 0
fi

msgs "Installing $PKG (this may take awhile...)"

if (( $+commands[pkginstall.sh] ))
then
	pkginstall.sh "$FILENAME"
else
	sudo /usr/sbin/installer -verbose -pkg "$PKG" -target / -lang en 2>&1 | tee -a "$LOG"
fi

EXIT="$?"

if [ "$EXIT" = "0" ]
then

	msg "Successfully installed XQuartz.app version $LATEST_VERSION"

	diskutil eject "$MNTPNT"

else
	msg "FAILED to install XQuartz.app version $LATEST_VERSION (exit = $EXIT)"

	exit 1
fi

exit
#
#EOF
