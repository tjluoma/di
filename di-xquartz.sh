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

	## This appears to be old
	## XML_FEED='http://xquartz.macosforge.org/downloads/sparkle/release.xml'
	# Found new appcast URL in "/usr/local/Homebrew/Library/Taps/homebrew/homebrew-cask/Casks/xquartz.rb"
	##
	## The app seems to show 'https://www.xquartz.org/releases/sparkle/beta.xml' as the Sparkle URL

XML_FEED='https://www.xquartz.org/releases/sparkle/release.xml'

# sparkle:shortVersionString exists in the feed, but sparkle:version seems to be the important number to check

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

	COUNT='0'

	while [ -e "$MNTPNT" ]
	do
		((COUNT++))

		if [ "$COUNT" -gt "10" ]
		then
			exit 0
		fi
			# unmount the DMG
		diskutil eject "$MNTPNT" || sleep 5
	done

	if [ ! -e "$MNTPNT" ]
	then
		msg "Unmounted $MNTPNT"
	fi

	exit 0

else
	msg "FAILED to install XQuartz.app version $LATEST_VERSION (exit = $EXIT)"
	exit 1
fi


exit
#
#EOF
