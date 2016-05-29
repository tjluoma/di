#!/bin/zsh -f
# Download and install (or update) Xquartz
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2014-06-10
#
## In case you need them:
# GENERAL_URL='https://xquartz.macosforge.org/landing/'
# DOWNLOAD_URL='http://xquartz.macosforge.org/trac/wiki/Releases'

## 2016-05-22 - new XML_FEED is much faster, so no longer using cache 

NAME="$0:t:r"

zmodload zsh/datetime

function timestamp { strftime "%Y-%m-%d--%H.%M.%S" "$EPOCHSECONDS" }

INSTALL_TO='/Applications/Utilities/XQuartz.app'

INSTALLED_VERSION=`defaults read "${INSTALL_TO}/Contents/Info.plist" "CFBundleVersion" 2>/dev/null || echo '0'`

########################################################################################################################

XML_FEED="https://www.xquartz.org/releases/sparkle/release.xml"

INFO=($(curl -sfL "$XML_FEED" | tr -s ' ' '\012' | egrep 'sparkle:version=|url=' | head -2 | awk -F'"' '/^/{print $2}'))

URL="$INFO[1]"

LATEST_VERSION="$INFO[2]"

########################################################################################################################

FILENAME="XQuartz-$LATEST_VERSION.dmg"

zmodload zsh/datetime

TIME=$(strftime "%Y-%m-%d-at-%H.%M.%S" "$EPOCHSECONDS")

HOST=`hostname -s`
HOST="$HOST:l"

LOG="$HOME/Library/Logs/metalog/$NAME/$HOST/$TIME.txt"

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


cd "$HOME/Downloads" || cd "$HOME/Desktop" || cd "$HOME" || cd /tmp


echo "$NAME: Saving $URL to $PWD/$FILENAME"
curl -C - --max-time 3600 --fail --location --referer ";auto" --progress-bar --output "${FILENAME}" "${URL}"


[[ ! -e "$FILENAME" ]] && echo "$NAME: $FILENAME does not exist." && exit 0

[[ ! -s "$FILENAME" ]] && echo "$NAME: $FILENAME is zero bytes." && exit 0



MNTPNT=$(echo -n "Y" | hdid -plist "$FILENAME" 2>/dev/null | fgrep -A 1 '<key>mount-point</key>' | tail -1 | sed 's#</string>.*##g ; s#.*<string>##g')

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

msgs "Installing $PKG (this will take awhile...)"

sudo installer -verbose -pkg "$PKG" -target / -lang en 2>&1 | tee -a "$LOG"

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
